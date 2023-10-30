// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title CarvMemberships Collection
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract CarvMemberships is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    // DEFAULT_ADMIN_ROLE - 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");  // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");  // 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3

    struct Permit {
        address to;
        string uri;
        uint128 expiredTime;
        bytes32 id;
    }

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address to,string uri,uint128 expiredTime,bytes32 id)");
    // Mapping used permit ids, signer could use this id to avoid duplicate mints.
    mapping(bytes32 => bool) private _permits;

    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;

    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);
    event MembershipSubscribed(address indexed member, uint256 indexed tokenId);
    event MembershipUnsubscribed(address indexed member, uint256 indexed tokenId);
    event MembershipSubscribedWithPermit(address indexed signer, address indexed member, uint256 indexed tokenId);

    function initialize() initializer public {
        __ERC721_init("Carv Memberships", "CARV-MEMBERSHIPS");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function subscribe(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _subscribe(to, uri);
        emit MembershipSubscribed(to, tokenId);
    }

    function _subscribe(address to, string memory uri) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function currentCounter() external view returns (uint256) {
        return (_tokenIdCounter.current());
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        if (from != address(0) && to != address(0)) {
            revert("CarvMembership: Soulbound tokens are nontransferable");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function unsubscribeBatch(uint256[] memory ids) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            _unsubscribe(tokenId);
        }
    }

    function unsubscribe(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _unsubscribe(tokenId);
    }

    function _unsubscribe(uint256 tokenId) private {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(owner != address(0), "member subscribed not found");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function addTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _trustedForwarders[forwarder] = true;
        emit TrustedForwarderAdded(forwarder);
    }

    function removeTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _trustedForwarders[forwarder];
        emit TrustedForwarderRemoved(forwarder);
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return _trustedForwarders[forwarder];
    }

    function _msgSender() internal view override returns (address sender) {
        // For ERC2771 transaction sender
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            return sender;
        }
        // For custom meta transaction sender
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
            return sender;
        }
        return super._msgSender();
    }

    function subscribeWithPermit(Permit calldata _req, bytes calldata _signature) external {
        address signer = recoverPermitSigner(_req, _signature);
        _checkRole(MINTER_ROLE, signer);
        require(_req.expiredTime > block.timestamp, "permit expired");
        require(!_permits[_req.id], "duplicated permit id");
        _permits[_req.id] = true;

        uint256 tokenId = _subscribe(_req.to, _req.uri);
        emit MembershipSubscribedWithPermit(signer, _req.to, tokenId);
    }

    // Returns the address of the signer of the mint permit.
    function recoverPermitSigner(Permit calldata _req, bytes calldata _signature) internal view returns (address) {
        require(_HASHED_NAME != bytes32(0) && _HASHED_VERSION != bytes32(0), "domain separator parameter not initialized");
        bytes32 domainSeparator = keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        bytes32 structHash = keccak256(_encodePermit(_req));
        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(domainSeparator, structHash);
        return ECDSAUpgradeable.recover(hash, _signature);
    }

    function _encodePermit(Permit calldata _req) internal pure returns (bytes memory) {
        return abi.encode(
            PERMIT_TYPEHASH,
            _req.to,
            _req.uri,
            _req.expiredTime,
            _req.id
        );
    }

    function setDomainSeparatorParameters(string memory name, string memory version) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }
}
