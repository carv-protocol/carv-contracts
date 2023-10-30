// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


/**
 * @title CarvEvents
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract CarvEvents is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {

    // Collection name
    string private _name;
    // Collection symbol
    string private _symbol;
    // Mapping from badge ID to the max supply amount
    mapping(uint256 => uint256) private _maxSupply;
    // Mapping from badge ID to the carved amount
    mapping(uint256 => uint256) private _carvedAmount;
    // Global supply of all token IDs
    uint256 private _globalSupply;
    // Indicator of whether a badge ID is synthetic
    mapping(uint256 => bool) private _synthetic;
    // Indicator of whether a Synthetic badge ID is open to carv;
    mapping(uint256 => bool) private _openToCarv;
    // Mapping from badge ID to ingredient badge IDs
    mapping(uint256 => uint256[]) private _ingredientBadgeIds;
    // Mapping from badge ID to ingredient badge amounts
    mapping(uint256 => uint256[]) private _ingredientBadgeAmounts;
    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;
    // Indicator of whether a badge ID is nontransferrable
    mapping(uint256 => bool) private _nontransferrable;
    // Mapping signature used per transaction(deprecated).
    mapping(uint256 => bool) private minted;
    // Mapping used nonce.
    mapping(address => uint256) private _nonces;

    // DEFAULT_ADMIN_ROLE - 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");  // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");  // 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3
    bytes32 public constant MANAGE_SBT_ROLE = keccak256("MANAGE_SBT_ROLE");

    // Used for mint with permit.
    struct Permit {
        address to;
        uint256 tokenId;
        uint256 amount;
        uint128 expiredTime;
        bytes32 id;
    }

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address to,uint256 tokenId,uint256 amount,uint128 expiredTime,bytes32 id)");
    // Mapping used permit ids, signer could use this id to avoid duplicate mints.
    mapping(bytes32 => bool) private _permits;

    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);
    event MaxSupplySet(uint256 indexed tokenId, uint256 maxSupply);
    event SyntheticSet(uint256 indexed tokenId, bool synthetic);
    event NontransferrableSet(uint256 indexed tokenId, bool nontransferrable);
    event OpenToCarvSet(uint256 indexed tokenId, bool openToCarv);
    event IngredientBadgesSet(uint256 indexed tokenId, uint256[] indexed ingredientBadgeIds, uint256[] indexed ingredientBadgeAmounts);
    event SyntheticCarved(address indexed to, uint256 indexed tokenId, uint256 amount);
    event EventsCarved(address indexed to, uint256[] indexed tokenIds, uint256[] amounts);
    event EventsCarvedWithPermit(address indexed signer, address indexed receiver, uint256[] tokenIds, uint256[] amounts);

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _name = "Carv Events";
        _symbol = "CARV-EVNT";
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function addTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _trustedForwarders[forwarder] = true;
        emit TrustedForwarderAdded(forwarder);
    }

    function removeTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _trustedForwarders[forwarder];
        emit TrustedForwarderRemoved(forwarder);
    }

    function uri(uint256 tokenId) override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) public view returns (string memory) {
        return super.uri(tokenId);
    }

    function setURI(uint256 tokenId, string memory tokenURI) external onlyRole(MANAGE_SBT_ROLE) {
        _setURI(tokenId, tokenURI);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function maxSupply(uint256 id) external view returns (uint256) {
        return (_maxSupply[id]);
    }

    function setMaxSupply(uint256 id, uint256 newMaxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply[id] = newMaxSupply;
        emit MaxSupplySet(id, newMaxSupply);
    }

    function carvedAmount(uint256 id) external view returns (uint256) {
        return (_carvedAmount[id]);
    }

    function totalSupply() external view returns (uint256) {
        return (_globalSupply);
    }

    function nontransferrable(uint256 id) external view returns (bool) {
        return (_nontransferrable[id]);
    }

    function setNontransferrable(uint256 id, bool newNontransferrable) external onlyRole(MANAGE_SBT_ROLE) {
        _nontransferrable[id] = newNontransferrable;
        emit NontransferrableSet(id, newNontransferrable);
    }

    function synthetic(uint256 id) external view returns (bool) {
        return (_synthetic[id]);
    }

    function setSynthetic(uint256 id, bool newIsSynthetic) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _synthetic[id] = newIsSynthetic;
        emit SyntheticSet(id, newIsSynthetic);
    }

    function openToCarv(uint256 id) external view returns (bool) {
        return (_openToCarv[id]);
    }

    function setOpenToCarv(uint256 id, bool newOpenToCarv) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _openToCarv[id] = newOpenToCarv;
        emit OpenToCarvSet(id, newOpenToCarv);
    }

    function ingredientBadgeIds(uint256 id) external view returns (uint256[] memory) {
        return (_ingredientBadgeIds[id]);
    }

    function ingredientBadgeAmounts(uint256 id) external view returns (uint256[] memory) {
        return (_ingredientBadgeAmounts[id]);
    }

    // Set the ingredient badge(token) IDs and amounts required to carv the synthetic badge
    function setIngredientBadges(uint256 id, uint256[] memory newIngredientBadgeIds, uint256[] memory newIngredientBadgeAmounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_synthetic[id], "CarvEvents: Token ID is not synthetic");
        require(newIngredientBadgeIds.length > 0 && newIngredientBadgeIds.length == newIngredientBadgeAmounts.length, "CarvEvents: Ingredient token IDs and amounts should have the same length greater than zero");
        _ingredientBadgeIds[id] = newIngredientBadgeIds;
        _ingredientBadgeAmounts[id] = newIngredientBadgeAmounts;
        emit IngredientBadgesSet(id, newIngredientBadgeIds, newIngredientBadgeAmounts);
    }

    // Burn ingredient badges to carv synthetic badges
    function carvSynthetic(uint256 id, uint256 amount) external {
        require(_synthetic[id], "CarvEvents: Badge is not synthetic");
        require(_ingredientBadgeAmounts[id].length > 0, "CarvEvents: Ingredient badges are not set");
        require(_openToCarv[id], "CarvEvents: Badge is not open to carv");
        uint256[] memory burnBadgeAmounts = new uint256[](_ingredientBadgeAmounts[id].length);
        for (uint256 i = 0; i < _ingredientBadgeAmounts[id].length; i++) {
            burnBadgeAmounts[i] = _ingredientBadgeAmounts[id][i] * amount;
        }
        _burnBatch(_msgSender(), _ingredientBadgeIds[id], burnBadgeAmounts);
        _mint(_msgSender(), id, amount, "");
        emit SyntheticCarved(_msgSender(), id, amount);
    }

    function carv(address to, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, "");
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);
        emit EventsCarved(to, ids, amounts);
    }

    function carvBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
        emit EventsCarved(to, ids, amounts);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(totalSupply(ids[i]) >= amounts[i], "ERC1155Supply: Insufficient supply");
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(_maxSupply[ids[i]] == 0 || _carvedAmount[ids[i]] + amounts[i] <= _maxSupply[ids[i]], "CarvEvents: Insufficient supply");
                _carvedAmount[ids[i]] += amounts[i];
                _globalSupply += amounts[i];
            }
        }

        // Require tokenIds to be transferable
        if (from != address(0) && to != address(0)) {
            revert("CarvEvents: Soulbound event tokens are nontransferable");
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
    * Below functions are for ERC2771 support
    */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return _trustedForwarders[forwarder];
    }

    /**
    * Below functions are for meta transaction personal signature support
    */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function metaCarv(address userAddr, uint256 nonce, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns (bytes memory) {

        require(verify(userAddr, nonce, getChainID(), functionSignature, sigR, sigS, sigV), "Signer and signature do not match");
        require(!minted[nonce], "Already carved");
        minted[nonce] = true;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddr));
        require(success, "Function call not successful");
        return returnData;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(address userAddr, uint256 nonce, uint256 chainID, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {
        bytes32 hash = prefixed(keccak256(abi.encodePacked(nonce, this, chainID, functionSignature)));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (userAddr == signer);
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
     * Below functions are for upgrade from ownable to access control.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function grantRoleBatch(address to) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, to);
        _grantRole(MINTER_ROLE, to);
        _grantRole(UPGRADER_ROLE, to);
    }

    // Carv with permit
    function carvWithPermit(Permit calldata _req, bytes calldata _signature) external {
        address signer = recoverPermitSigner(_req, _signature);
        require(hasRole(MINTER_ROLE, signer), "missing minter role");
        require(_req.expiredTime > block.timestamp, "permit expired");
        require(!_permits[_req.id], "duplicated permit id");
        _permits[_req.id] = true;

        // start mint
        _mint(_req.to, _req.tokenId, _req.amount, "");
        uint256[] memory ids = _asSingletonArray(_req.tokenId);
        uint256[] memory amounts = _asSingletonArray(_req.amount);
        emit EventsCarvedWithPermit(signer, _req.to, ids, amounts);
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
            _req.tokenId,
            _req.amount,
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