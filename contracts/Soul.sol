// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// import "hardhat/console.sol";
contract Soul is ERC20Upgradeable,EIP712Upgradeable,AccessControlUpgradeable{

    /*
    *  Date and Time utilities for ethereum contracts
    *
    */
    struct _DateTime {
            uint16 year;
            uint8 month;
            uint8 day;
    }

    uint constant private DAY_IN_SECONDS = 86400;
    uint constant private YEAR_IN_SECONDS = 31536000;
    uint constant private LEAP_YEAR_IN_SECONDS = 31622400;
    uint16 constant private ORIGIN_YEAR = 1970;

    address private soul_singer;
    string private constant SIGNING_DOMAIN = "Soul";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;//keccak256("MINTER_ROLE"); 
    
    bytes32 private typeHash;
    mapping(address=>uint256) private addressTimeMap;
    
    event MintSoul(
        address account,
        uint256 amount,
        uint256 ymd
    );

    event MintParams(

        uint256 chainId,
        bytes32 eip712DomainHash,
        bytes32 hashStruct,
        bytes32 digest
    );


    error InvalidSigner();

    /// @notice Represents an MintStruct, which has not yet been recorded into the blockchain. 
    /// A signed voucher can be redeemed for a real NFT using the redeem function.
    struct MintData {
        address account;
        uint256 amount;
        uint256 ymd;
    }

    /**
        @notice Initializes CompaignsService, creates and grants {msg.sender} the admin role,
     */
    function __Soul_init(string memory _name,string memory _symbol) public initializer()  {

        soul_singer = msg.sender;
        typeHash = keccak256("MintData(address account,uint256 amount,uint256 ymd)");
 
        __EIP712_init(SIGNING_DOMAIN,SIGNATURE_VERSION);
        __ERC20_init(_name,_symbol);

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        revert("do not support");
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        revert("do not support");
    }
    
    function mintSoul(MintData calldata mintData, bytes memory signature) external{

        // make sure signature is valid and get the address of the signer
        address signer = _verify(mintData, signature);

        // if(!hasRole(MINTER_ROLE,signer)) revert InvalidSigner();
        require(hasRole(MINTER_ROLE,signer),"invald signer");
        require(addressTimeMap[mintData.account] < mintData.ymd,"You can only mint once a day");

        addressTimeMap[mintData.account] = mintData.ymd;
        _mint(mintData.account,mintData.amount);

        emit MintSoul(mintData.account,mintData.amount,mintData.ymd);

    }

    /// @notice Verifies the signature for a given MintData, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint FT.
    /// @param mintData An MintData describing an unminted FT.
    function _verify(MintData calldata mintData, bytes memory signature) internal returns (address) {

        uint256 chainId = uint256(block.chainid);
        // uint256 chainId = 5611;
        bytes32 eip712DomainHash = keccak256(
        abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId)"
                ),
                keccak256(bytes("Soul")),
                keccak256(bytes("1")),
                chainId
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("MintData(address account,uint256 amount,uint256 ymd)"),
                mintData.account,
                mintData.amount,
                mintData.ymd
            )
        );

        // 1. hashing the data (above is part of this) and generating the hashes 
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        emit MintParams(chainId,eip712DomainHash,hashStruct,digest);

        return ECDSAUpgradeable.recover(digest, signature);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    
    function burn(address account, uint256 amount) external {

        require(hasRole(DEFAULT_ADMIN_ROLE,msg.sender),"do not have admin role");
        super._burn(account,amount);
    }

}
