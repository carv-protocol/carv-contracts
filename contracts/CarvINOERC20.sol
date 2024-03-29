// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./@openzeppelin/contracts/access/AccessControl.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title CarvINOERC20 Collection
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract CarvINOERC20 is Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public nftCollection;               // NFT contract address
    address public paymentToken;                // Contract address of the payment token 
    uint public maxOfferCount;                  // Max # NFTs to be added
    uint public addedCount;                     // # NFTs already added
    uint public offerCount;                     // Index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type
    mapping(uint => uint) private offers;       // OfferId to tokenId mapping
    uint public unitPrice;                      // Unit price(Wei)
    uint public minPurchase = 1;                // Minimum NFT to buy per purchase
    uint public fund;                           // Payment tokens collected
    bool public requireWhitelist = true;        // If require whitelist
    mapping(address => uint) public whitelist;  // Address-to-claimable-amount mapping

    bytes32 public constant MAKE_OFFER_ROLE = keccak256("MAKE_OFFER_ROLE");    // Role that can add item to the offering
    bytes32 public constant CLAIM_FUND_ROLE = keccak256("CLAIM_FUND_ROLE");    // Role that can claim the collected fund
    bytes32 public constant CLAIM_STOCK_ROLE = keccak256("CLAIM_STOCK_ROLE");  // Role that can claim the remaining NFTs

    event NFTCollectionSet(address nftCollection);
    event PaymentTokenSet(address paymentToken);
    event UnitPriceSet(uint unitPrice);
    event MinPurchaseSet(uint minPurchase);
    event MaxOfferCountSet(uint maxAmount);
    event SetRequireWhitelist(bool requireWhitelist);
    event OffersAdded(uint addedCount);
    event WhitelistsAdded(uint addedCount);
    event OffersFilled(uint amount, uint totalPrice, address indexed filler);
    event FundClaimed(uint amount);
    event RemainingStockClaimed(uint amount);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CLAIM_STOCK_ROLE, msg.sender);
        _pause();
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nftCollection != address(0), "CarvINO: NFT contract address is not set");
        require(paymentToken != address(0), "CarvINO: ERC20 payment token is not set");
        require(unitPrice > 0, "CarvINO: Unit price is not set");
        _unpause();
    }

    function setNFTCollection(address _nftCollection) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        require(nftCollection == address(0), "CarvINO: nftCollection cannot be updated once set");
        require(_nftCollection != address(0), "CarvINO: _nftCollection is a zero address");
        nftCollection = _nftCollection;
        emit NFTCollectionSet(_nftCollection);
    }

    function setPaymentToken(address _paymentToken) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        require(paymentToken == address(0), "CarvINO: paymentToken cannot be updated once set");
        require(_paymentToken != address(0), "CarvINO: _paymentToken is a zero address");
        paymentToken = _paymentToken;
        emit PaymentTokenSet(_paymentToken);
    }

    function setUnitPrice(uint _unitPrice) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        unitPrice = _unitPrice;
        emit UnitPriceSet(_unitPrice);
    }

    function setMinPurchase(uint _minPurchase) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        minPurchase = _minPurchase;
        emit MinPurchaseSet(_minPurchase);
    }

    function setMaxOfferCount(uint _maxCount) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        maxOfferCount = _maxCount;
        emit MaxOfferCountSet(_maxCount);
    }

    function setRequireWhitelist(bool _requireWhitelist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        requireWhitelist = _requireWhitelist;
        emit SetRequireWhitelist(_requireWhitelist);
    }

    function setWhitelist(address _whitelisted, uint _claimable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelist[_whitelisted] = _claimable;
        emit WhitelistsAdded(1);
    }

    function setWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _claimable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_whitelisted.length == _claimable.length, "CarvINO: _whitelisted and _claimable should have the same length");
        for(uint i=0; i<_whitelisted.length; i++){
            whitelist[_whitelisted[i]] = _claimable[i];
        }
        emit WhitelistsAdded(_whitelisted.length);
    }

    function addOffer(uint _tokenId) external onlyRole(MAKE_OFFER_ROLE) whenPaused nonReentrant {
        require(addedCount < maxOfferCount, "CarvINO: Reached maxOfferCount");
        offerCount ++;
        addedCount ++;
        offers[offerCount] = _tokenId;
        IERC721(nftCollection).transferFrom(msg.sender, address(this), _tokenId);
        emit OffersAdded(1);
    }

    function addOfferBatch(uint[] calldata _tokenIds) external onlyRole(MAKE_OFFER_ROLE) whenPaused nonReentrant {
        require(addedCount + _tokenIds.length <= maxOfferCount, "CarvINO: Reached maxOfferCount");
        for(uint i=0; i<_tokenIds.length; i++){
            offerCount ++;
            addedCount ++;
            offers[offerCount] = _tokenIds[i];
            IERC721(nftCollection).transferFrom(msg.sender, address(this), offers[offerCount]);
        }
        emit OffersAdded(_tokenIds.length);
    }

    function fillOffers(uint _amount) external whenNotPaused nonReentrant {
        require(_amount >= minPurchase, "CarvINO: Amount must >= minPurchase");
        require(!requireWhitelist || _amount <= whitelist[msg.sender], "CarvINO: Insufficient claimable quota");
        require(offerCount >= _amount, "CarvINO: Insufficient stock");
        uint totalPrice = unitPrice * _amount;
        if (requireWhitelist) whitelist[msg.sender] -= _amount;
        fund += totalPrice;
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), totalPrice);
        for(uint i = 1; i <= _amount; i ++){
            IERC721(nftCollection).transferFrom(address(this), msg.sender, offers[offerCount]);
            offerCount --;
        }
        emit OffersFilled(_amount, totalPrice, msg.sender);
    }

    function claimFund() external onlyRole(CLAIM_FUND_ROLE) whenPaused nonReentrant {
        require(paymentToken != address(0), "CarvINO: ERC20 payment token is not set");
        require(fund > 0, "CarvINO: There is no fund to be claimed");
        uint toTransfer = fund;
        fund = 0;
        IERC20(paymentToken).safeTransfer(msg.sender, toTransfer);
        emit FundClaimed(toTransfer);
    }

    function claimRemainingStock(uint _amount) external onlyRole(CLAIM_STOCK_ROLE) whenPaused nonReentrant {
        require(nftCollection != address(0), "CarvINO: NFT contract address is not set");
        require(_amount > 0, "CarvINO: Amount must be greater than 0");
        require(_amount <= offerCount, "CarvINO: Insufficient stock");
        for(uint i = 1; i <= _amount; i ++){
            IERC721(nftCollection).transferFrom(address(this), msg.sender, offers[offerCount]);
            offerCount --;
        }
        emit RemainingStockClaimed(_amount);
    }

    function getOffer(uint _offerId) external view onlyRole(DEFAULT_ADMIN_ROLE) returns(uint tokenId) {
        tokenId = offers[_offerId];
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback () external {
        revert();
    }
}
