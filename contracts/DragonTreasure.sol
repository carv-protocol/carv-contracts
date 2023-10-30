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
import "./operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title Dragon Treasure Collection
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract DragonTreasure is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, ERC2981Upgradeable, DefaultOperatorFiltererUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");  // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");  // 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3

    CountersUpgradeable.Counter private _tokenIdCounter;

    // Owner of the contract, for OpenSea compatibility.
    address private _owner;
    // Mapping signature used per transaction.
    mapping(uint256 => bool) private minted;
    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;

    event TreasureMinted(address indexed to, uint256 indexed tokenId);
    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);
    event DefaultRoyaltyUpdated(address receiver, uint96 feeNumerator);
    event TokenRoyaltyUpdated(uint256 tokenId, address receiver, uint96 feeNumerator);
    event OwnerUpdated(address prevOwner, address newOwner);

    function initialize(address _forwarder, address _royaltyReceiver, uint96 _royaltyFeeNumerator) initializer external {
        __ERC721_init("DragonTreasure", "DRGNT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __DefaultOperatorFilterer_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        setOwner(msg.sender);
        addTrustedForwarder(_forwarder);
        setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    function mint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit TreasureMinted(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mintedAmount() external view returns (uint256) {
        return (_tokenIdCounter.current());
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

    function addTrustedForwarder(address forwarder) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _trustedForwarders[forwarder] = true;
        emit TrustedForwarderAdded(forwarder);
    }

    function removeTrustedForwarder(address forwarder) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _trustedForwarders[forwarder];
        emit TrustedForwarderRemoved(forwarder);
    }

    /**
    * Below functions are for ERC2771 support
    */
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

    /**
     * Below functions are for Opensea royalty support
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltyUpdated(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltyUpdated(tokenId, receiver, feeNumerator);
    }

    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    function setOwner(address _newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not admin.");
        address _prevOwner = _owner;
        _owner = _newOwner;
        emit OwnerUpdated(_prevOwner, _newOwner);
    }


    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }


    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }


    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
