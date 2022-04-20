// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title CarvEvents Collection
 * @author Carv.xyz
 * @custom:security-contact security@carv.xyz
 */
contract CarvEvents is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    // Collection name
    string private _name;

    // Collection symbol
    string private _symbol;

    // Mapping from badge ID to token URI
    mapping(uint256 => string) private _uris;

    // Mapping from badge ID to the max supply amount
    mapping(uint256 => uint256) private _maxSupply;

    // Mapping from badge ID to the carved amount
    mapping(uint256 => uint256) private _carvedAmount;

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

    constructor() ERC1155("https://carv.xyz") {
        _name = "Carv Events";
        _symbol = "CARV-EVNT";
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function addTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarders[forwarder] = true;
    }

    function removeTrustedForwarder(address forwarder) external onlyOwner {
        delete _trustedForwarders[forwarder];
    }

    function uri(uint256 id) override external view returns (string memory) {
        return(_uris[id]);
    }

    function setTokenURI(uint256 id, string memory tokenURI) external onlyOwner {
        _uris[id] = tokenURI;
    }

    function maxSupply(uint256 id) external view returns (uint256) {
        return(_maxSupply[id]);
    }

    function setMaxSupply(uint256 id, uint256 newMaxSupply) external onlyOwner {
        _maxSupply[id] = newMaxSupply;
    }

    function carvedAmount(uint256 id) external view returns (uint256) {
        return(_carvedAmount[id]);
    }

    function synthetic(uint256 id) external view returns (bool) {
        return(_synthetic[id]);
    }

    function setSynthetic(uint256 id, bool newIsSynthetic) external onlyOwner {
        _synthetic[id] = newIsSynthetic;
    }

    function openToCarv(uint256 id) external view returns (bool) {
        return(_openToCarv[id]);
    }

    function setOpenToCarv(uint256 id, bool newOpenToCarv) external onlyOwner {
        _openToCarv[id] = newOpenToCarv;
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
    }

    function carv(address account, uint256 id, uint256 amount) external onlyOwner {
        _mint(account, id, amount, "");
    }

    function carvBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(totalSupply(ids[i]) >= amounts[i], "ERC1155Supply: Insufficient supply");
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(_maxSupply[ids[i]] == 0 || _carvedAmount[ids[i]] + amounts[i] <= _maxSupply[ids[i]], "CarvEvents: Insufficient supply");
                _carvedAmount[ids[i]] += amounts[i];
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
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }
}
