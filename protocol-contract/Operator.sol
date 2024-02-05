// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @title The Chainlink Operator contract
 * @notice Node operators can deploy this contract to fulfill requests sent to them
 */
contract Operator is OperatorInterface {

  uint256 public constant getExpiryTime = 5 minutes;
  uint256 private constant ONE_FOR_CONSISTENT_GAS_COST = 1;
  uint256 private s_tokensInEscrow = ONE_FOR_CONSISTENT_GAS_COST;
  uint256 private constant MAXIMUM_DATA_VERSION = 256;
  uint256 private constant MINIMUM_CONSUMER_GAS_LIMIT = 400000;

  LinkTokenInterface internal immutable linkToken;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event OracleResponse(bytes32 indexed requestId);

  mapping(bytes32 => Commitment) private s_commitments;

  struct Commitment {
    bytes31 paramsHash;
    uint8 dataVersion;
  }

  /**
   * @notice Deploy with the address of the LINK token
   * @dev Sets the LinkToken address for the imported LinkTokenInterface
   * @param link The address of the LINK token
   * @param owner The address of the owner
   */
  constructor(address link, address owner){
    linkToken = LinkTokenInterface(link); // external but already deployed and unalterable
  }

  /**
   * @notice Creates the Chainlink request
   * @dev Stores the hash of the params as the on-chain commitment for the request.
   * Emits OracleRequest event for the Chainlink node to detect.
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param specId The Job Specification ID
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   * @param dataVersion The specified data version
   * @param data The extra request parameters
   */
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external {

    (bytes32 requestId, uint256 expiration) = _verifyAndProcessOracleRequest(
      sender,
      payment,
      sender,
      callbackFunctionId,
      nonce,
      dataVersion
    );
    emit OracleRequest(specId, sender, requestId, payment, sender, callbackFunctionId, expiration, dataVersion, data);
  }

  /**
   * @notice Verify the Oracle Request and record necessary information
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param callbackAddress The callback address for the response
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   */
  function _verifyAndProcessOracleRequest(
    address sender,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion
  ) private returns (bytes32 requestId, uint256 expiration) {
    requestId = keccak256(abi.encodePacked(sender, nonce));

    require(s_commitments[requestId].paramsHash == 0, "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    expiration = block.timestamp + getExpiryTime;

    // expiration = block.timestamp;
    bytes31 paramsHash = _buildParamsHash(payment, callbackAddress, callbackFunctionId, expiration);
    s_commitments[requestId] = Commitment(paramsHash, _safeCastToUint8(dataVersion));
    // s_tokensInEscrow = s_tokensInEscrow.add(payment);

    s_tokensInEscrow = s_tokensInEscrow + payment ;
    return (requestId, expiration);
  }

  /**
   * @notice Called by the Chainlink node to fulfill requests with multi-word support
   * @dev Given params must hash back to the commitment stored from `oracleRequest`.
   * Will call the callback address' callback function without bubbling up error
   * checking in a `require` so that the node can get paid.
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @param data The data to return to the consuming contract
   * @return Status if the external call was successful
   */
  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    override
    returns (bool)
  {
    _verifyOracleRequestAndProcessPayment(requestId, payment, callbackAddress, callbackFunctionId, expiration, 2);
    emit OracleResponse(requestId);
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    (bool success, ) = callbackAddress.call(abi.encodePacked(callbackFunctionId, data)); // solhint-disable-line avoid-low-level-calls
    return success;
  }

  /**
   * @notice Verify the Oracle request and unlock escrowed payment
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   */
  function _verifyOracleRequestAndProcessPayment(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    uint256 dataVersion
  ) internal {
    bytes31 paramsHash = _buildParamsHash(payment, callbackAddress, callbackFunctionId, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    require(s_commitments[requestId].dataVersion <= _safeCastToUint8(dataVersion), "Data versions must match");
    s_tokensInEscrow = s_tokensInEscrow - payment;
    delete s_commitments[requestId];
  }

  /**
   * @notice Build the bytes31 hash from the payment, callback and expiration.
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @return hash bytes31
   */
  function _buildParamsHash(
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) internal pure returns (bytes31) {
    return bytes31(keccak256(abi.encodePacked(payment, callbackAddress, callbackFunctionId, expiration)));
  }

  /**
   * @notice Safely cast uint256 to uint8
   * @param number uint256
   * @return uint8 number
   */
  function _safeCastToUint8(uint256 number) internal pure returns (uint8) {
    require(number < MAXIMUM_DATA_VERSION, "number too big to cast");
    return uint8(number);
  }

  /**
   * @notice Interact with other LinkTokenReceiver contracts by calling transferAndCall
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   * @param data The extra data to be passed to the receiving contract.
   * @return success bool
   */
  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external override returns (bool success) {
    return linkToken.transferAndCall(to, value, data);
  }


  /**
   * @notice Distribute funds to multiple addresses using ETH send
   * to this payable function.
   * @dev Array length must be equal, ETH sent must equal the sum of amounts.
   * A malicious receiver could cause the distribution to revert, in which case
   * it is expected that the address is removed from the list.
   * @param receivers list of addresses
   * @param amounts list of amounts
   */
  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable {
    require(receivers.length > 0 && receivers.length == amounts.length, "Invalid array length(s)");
    uint256 valueRemaining = msg.value;
    for (uint256 i = 0; i < receivers.length; i++) {
      uint256 sendAmount = amounts[i];
      valueRemaining = valueRemaining - sendAmount;
      receivers[i].transfer(sendAmount);
    }
    require(valueRemaining == 0, "Too much ETH sent");
  }

//TODO
function getAuthorizedSenders() external returns (address[] memory){
  
  address[] memory ret;
  return ret;

}

//TODO
function setAuthorizedSenders(address[] calldata senders) external{

}

//TODO
function getForwarder() external returns (address){

  address ret;
  return ret;
}



}
