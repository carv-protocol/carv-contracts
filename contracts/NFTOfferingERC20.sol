// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTOfferingERC20 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(uint8 => bool) public supportedTypes;                 // Map from NFT type to supported status
    mapping(uint8 => address) public nftCollections;              // Map from NFT type to NFT contract address
    mapping(uint8 => address) public paymentTokens;               // Map from NFT type to contract address of the payment token 
    mapping(uint8 => uint) public maxOfferCounts;                 // Map from NFT type to max # NFTs to be added
    mapping(uint8 => uint) public addedCounts;                    // Map from NFT type to # NFTs already added
    mapping(uint8 => uint) public offerCounts;                    // Map from NFT type to index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type.
    mapping(uint8 => mapping(uint => uint)) public offers;        // Map from NFT type to offerId-to-tokenId mapping
    mapping(uint8 => uint) public unitPrices;                     // Map from NFT type to unit price(Wei).
    mapping(uint8 => uint) public funds;                          // Map from NFT type to payment tokens collected
    mapping(uint8 => bool) public paused;                         // Map from NFT type to start status
    mapping(uint8 => mapping(address => uint)) public whitelist;  // Map from NFT type to address-to-claimable-amount mapping

    bytes32 public constant MAKE_OFFER_ROLE = keccak256("MAKE_OFFER_ROLE");    // Role that can add item to the offering
    bytes32 public constant CLAIM_FUND_ROLE = keccak256("CLAIM_FUND_ROLE");    // Role that can claim the collected fund
    bytes32 public constant CLAIM_STOCK_ROLE = keccak256("CLAIM_STOCK_ROLE");  // Role that can claim the remaining NFTs

    event SupportedTypeSet(uint8 nftType, bool supported);
    event NFTCollectionSet(uint8 nftType, address nftCollection);
    event PaymentTokenSet(uint8 nftType, address paymentToken);
    event UnitPriceSet(uint8 nftType, uint unitPrice);
    event MaxOfferCountSet(uint8 nftType, uint maxAmount);
    event Paused(uint8 nftType);
    event UnPaused(uint8 nftType);
    event OfferAdded(uint8 nftType);
    event WhitelistAdded(uint8 nftType);
    event OfferFilled(uint8 nftType, uint amount, uint totalPrice, address filler);
    event FundClaimed();
    event RemainingStockClaimed(uint8 nftType);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CLAIM_STOCK_ROLE, msg.sender);
    }

    modifier typeSupported(uint8 _type) {
        require(supportedTypes[_type], "NFT type not supported");
        _;
    }

    modifier inPause(uint8 _type) {
        require(paused[_type], "Claims in progress");
        _;
    }

    modifier inProgress(uint8 _type) {
        require(!paused[_type], "Claims paused");
        _;
    }

    function setSupportedType(uint8 _type, bool _supported) public onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedTypes[_type] = _supported;
        paused[_type] = true;
        emit SupportedTypeSet(_type, _supported);
        emit Paused(_type);
    }

    function setNFTCollection(uint8 _type, address _nftCollection) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        require(nftCollections[_type] == address(0), "nftCollection cannot be updated once set");
        require(_nftCollection != address(0), "_nftCollection is a zero address");
        nftCollections[_type] = _nftCollection;
        emit NFTCollectionSet(_type, _nftCollection);
    }

    function setPaymentToken(uint8 _type, address _paymentToken) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        require(paymentTokens[_type] == address(0), "paymentToken cannot be updated once set");
        require(_paymentToken != address(0), "_paymentToken is a zero address");
        paymentTokens[_type] = _paymentToken;
        emit PaymentTokenSet(_type, _paymentToken);
    }

    function setUnitPrice(uint8 _type, uint _unitPrice) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        unitPrices[_type] = _unitPrice;
        emit UnitPriceSet(_type, _unitPrice);
    }

    function setMaxOfferCount(uint8 _type, uint _maxCount) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        maxOfferCounts[_type] = _maxCount;
        emit MaxOfferCountSet(_type, _maxCount);
    }

    function pause(uint8 _type) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inProgress(_type) {
        paused[_type] = true;
        emit Paused(_type);
    }

    function unpause(uint8 _type) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        require(nftCollections[_type] != address(0), "NFT contract address is not set");
        require(paymentTokens[_type] != address(0), "ERC20 payment token is not set");
        require(unitPrices[_type]>0, "Unit price is not set");
        paused[_type] = false;
        emit UnPaused(_type);
    }

    function addWhitelist(uint8 _type, address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) typeSupported(_type) inPause(_type) {
        whitelist[_type][_whitelisted] = _claimable;
        emit WhitelistAdded(_type);
    }

    function addOffer(uint8 _type, uint _tokenId) public onlyRole(MAKE_OFFER_ROLE) typeSupported(_type) inPause(_type) nonReentrant {
        require(addedCounts[_type] < maxOfferCounts[_type], "Reached maxOfferCount");
        offerCounts[_type] ++;
        addedCounts[_type] ++;
        offers[_type][offerCounts[_type]] = _tokenId;
        IERC721(nftCollections[_type]).transferFrom(msg.sender, address(this), _tokenId);
        emit OfferAdded(_type);
    }

    function fillOffers(uint8 _type, uint _amount) public typeSupported(_type) inProgress(_type) nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= whitelist[_type][msg.sender], "Insufficient claimable quota");
        require(offerCounts[_type] >= _amount, "Insufficient stock");
        uint totalPrice = unitPrices[_type] * _amount;
        whitelist[_type][msg.sender] -= _amount;
        funds[_type] += totalPrice;
        IERC20(paymentTokens[_type]).safeTransferFrom(msg.sender, address(this), totalPrice);
        for(uint i = 1; i <= _amount; i ++){
            IERC721(nftCollections[_type]).transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
        emit OfferFilled(_type, _amount, totalPrice, msg.sender);
    }

    function claimFund(uint8 _type) public onlyRole(CLAIM_FUND_ROLE) typeSupported(_type) inPause(_type) nonReentrant {
        require(paymentTokens[_type] != address(0), "ERC20 payment token is not set");
        require(funds[_type] > 0, "There is no fund to be claimed");
        uint toTransfer = funds[_type];
        funds[_type] = 0;
        IERC20(paymentTokens[_type]).safeTransfer(msg.sender, toTransfer);
        emit FundClaimed();
    }

    function claimRemainingStock(uint8 _type, uint _amount) public onlyRole(CLAIM_STOCK_ROLE) typeSupported(_type) inPause(_type) nonReentrant {
        require(nftCollections[_type] != address(0), "NFT contract address is not set");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= offerCounts[_type], "Insufficient stock");
        for(uint i = 1; i <= _amount; i ++){
            IERC721(nftCollections[_type]).transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
        emit RemainingStockClaimed(_type);
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback () external {
        revert();
    }
}
