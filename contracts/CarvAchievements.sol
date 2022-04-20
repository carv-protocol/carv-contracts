// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact security@carv.xyz
contract CarvAchievements is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;

    bool private _transferable = false;

    constructor() ERC721("Carv Achievements", "CARV-ACHV") {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function addTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarders[forwarder] = true;
    }

    function removeTrustedForwarder(address forwarder) external onlyOwner {
        delete _trustedForwarders[forwarder];
    }

    function transferable() external view returns (bool) {
        return(_transferable);
    }

    function setTransferable(bool newTransferable) external onlyOwner {
        _transferable = newTransferable;
    }

    function carv(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function carvedAmount() external view returns (uint256) {
        return(_tokenIdCounter.current());
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        if (from != address(0) && to != address(0)) {
            require(_transferable, "CarvAchievements: Achievement badges are not directly transferable. Use Carv to teleport badges among wallets you own");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI) external onlyOwner {
        _setTokenURI(tokenId, newTokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
    * Support:
    *   - Upgrading lower-tier badges to the higher-tier ones
    *   - Moving achievement badges among addresses of the same carver
    */
    function recarv(address to, uint256 oldTokenId, string memory newTokenURI) external onlyOwner {
        _burn(oldTokenId);
        carv(to, newTokenURI);
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
