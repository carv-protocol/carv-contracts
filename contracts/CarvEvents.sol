// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title CarvEvents
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract CarvEvents is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable, UUPSUpgradeable {

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
    // Indicator of if a badge ID is synthetic
    mapping(uint256 => bool) private _synthetic;
    // Indicator of if a Synthetic badge ID is open to carv;
    mapping(uint256 => bool) private _openToCarv;
    // Mapping from badge ID to ingredient badge IDs
    mapping(uint256 => uint256[]) private _ingredientBadgeIds;
    // Mapping from badge ID to ingredient badge amounts
    mapping(uint256 => uint256[]) private _ingredientBadgeAmounts;
    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;

    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);
    event MaxSupplySet(uint256 indexed tokenId, uint256 maxSupply);
    event SyntheticSet(uint256 indexed tokenId, bool synthetic);
    event OpenToCarvSet(uint256 indexed tokenId, bool openToCarv);
    event IngredientBadgesSet(uint256 indexed tokenId, uint256[] indexed ingredientBadgeIds, uint256[] indexed ingredientBadgeAmounts);
    event SyntheticCarved(address indexed to, uint256 indexed tokenId, uint256 amount);
    event EventsCarved(address indexed to, uint256[] indexed tokenIds, uint256[] amounts);

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();
        _name = "Carv Events";
        _symbol = "CARV-EVNT";
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function addTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarders[forwarder] = true;
        emit TrustedForwarderAdded(forwarder);
    }

    function removeTrustedForwarder(address forwarder) external onlyOwner {
        delete _trustedForwarders[forwarder];
        emit TrustedForwarderRemoved(forwarder);
    }

    function uri(uint256 tokenId) override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) public view returns (string memory) {
        return super.uri(tokenId);
    }

    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function maxSupply(uint256 id) external view returns (uint256) {
        return(_maxSupply[id]);
    }

    function setMaxSupply(uint256 id, uint256 newMaxSupply) external onlyOwner {
        _maxSupply[id] = newMaxSupply;
        emit MaxSupplySet(id, newMaxSupply);
    }

    function carvedAmount(uint256 id) external view returns (uint256) {
        return(_carvedAmount[id]);
    }

    function totalSupply() external view returns (uint256) {
        return(_globalSupply);
    }

    function synthetic(uint256 id) external view returns (bool) {
        return(_synthetic[id]);
    }

    function setSynthetic(uint256 id, bool newIsSynthetic) external onlyOwner {
        _synthetic[id] = newIsSynthetic;
        emit SyntheticSet(id, newIsSynthetic);
    }

    function openToCarv(uint256 id) external view returns (bool) {
        return(_openToCarv[id]);
    }

    function setOpenToCarv(uint256 id, bool newOpenToCarv) external onlyOwner {
        _openToCarv[id] = newOpenToCarv;
        emit OpenToCarvSet(id, newOpenToCarv);
    }

    function ingredientBadgeIds(uint256 id) external view returns (uint256[] memory) {
        return(_ingredientBadgeIds[id]);
    }

    function ingredientBadgeAmounts(uint256 id) external view returns (uint256[] memory) {
        return(_ingredientBadgeAmounts[id]);
    }

    // Set the ingredient badge(token) IDs and amounts required to carv the synthetic badge
    function setIngredientBadges(uint256 id, uint256[] memory newIngredientBadgeIds, uint256[] memory newIngredientBadgeAmounts) external onlyOwner {
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

    function carv(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);
        emit EventsCarved(to, ids, amounts);
    }

    function carvBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
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

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
    * Below functions are for ERC2771 support
    */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return _trustedForwarders[forwarder];
    }

    function _msgSender() internal view override returns (address sender) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }
}
