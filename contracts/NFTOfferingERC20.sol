// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTOfferingERC20 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(uint => bool) public supportedTypes;                 // Map from NFT type to supported status
    mapping(uint => address) public paymentTokens;               // Map from NFT type to contract address of the payment token 
    mapping(uint => uint) public maxOfferCounts;                 // Map from NFT type to max # NFTs to be added
    mapping(uint => uint) public addedCounts;                    // Map from NFT type to # NFTs already added
    mapping(uint => uint) public offerCounts;                    // Map from NFT type to index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type.
    mapping(uint => mapping(uint => uint)) public offers;        // Map from NFT type to offerId-to-tokenId mapping
    mapping(uint => uint) public unitPrices;                     // Map from NFT type to unit price(Wei).
    mapping(uint => uint) public funds;                          // Map from NFT type to payment tokens collected
    IERC721 nftCollection;                                       // The supported NFT collection
    bool public paused = true;                                   // If the claiming is paused
    mapping(uint => mapping(address => uint)) public whitelist;  // Map from NFT type to address-to-claimable-amount mapping

    bytes32 public constant MAKE_OFFER_ROLE = keccak256("MAKE_OFFER_ROLE");    // Role that can add item to the offering
    bytes32 public constant CLAIM_FUND_ROLE = keccak256("CLAIM_FUND_ROLE");    // Role that can claim the collected fund
    bytes32 public constant CLAIM_STOCK_ROLE = keccak256("CLAIM_STOCK_ROLE");  // Role that can claim the remaining NFTs

    event SupportedTypeSet(uint nftType, bool supported);
    event PaymentTokenSet(uint nftType, address paymentToken);
    event UnitPriceSet(uint nftType, uint unitPrice);
    event MaxOfferCountSet(uint nftType, uint maxAmount);
    event Paused();
    event UnPaused();
    event OfferAdded(uint nftType);
    event WhitelistAdded(uint nftType);
    event OfferFilled(uint nftType, uint amount, uint totalPrice, address filler);
    event FundClaimed();
    event RemainingStockClaimed();

    constructor(address _nftCollection) {
        require(_nftCollection != address(0), "_nftCollection is a zero address");
        nftCollection = IERC721(_nftCollection);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CLAIM_STOCK_ROLE, msg.sender);
    }

    modifier inPause() {
        require(paused, "Claims in progress");
        _;
    }

    modifier inProgress() {
        require(!paused, "Claims paused");
        _;
    }

    function setSupportedType(uint _type, bool _supported) public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        supportedTypes[_type] = _supported;
        emit SupportedTypeSet(_type, _supported);
    }

    function setPaymentToken(uint _type, address _paymentToken) public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        require(supportedTypes[_type], "NFT type not supported");
        paymentTokens[_type] = _paymentToken;
        emit PaymentTokenSet(_type, _paymentToken);
    }

    function setUnitPrice(uint _type, uint _unitPrice) public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        require(supportedTypes[_type], "NFT type not supported");
        require(paymentTokens[_type] != address(0), "ERC20 payment token is not set");
        unitPrices[_type] = _unitPrice;
        emit UnitPriceSet(_type, _unitPrice);
    }

    function setMaxOfferCount(uint _type, uint _maxCount) public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        require(supportedTypes[_type], "NFT type not supported");
        maxOfferCounts[_type] = _maxCount;
        emit MaxOfferCountSet(_type, _maxCount);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) inProgress {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        paused = false;
        emit UnPaused();
    }

    function addWhitelist(uint _type, address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) inPause {
        require(supportedTypes[_type], "NFT type not supported");
        whitelist[_type][_whitelisted] = _claimable;
        emit WhitelistAdded(_type);
    }

    function addOffer(uint _type, uint _tokenId) public onlyRole(MAKE_OFFER_ROLE) inPause nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(addedCounts[_type] < maxOfferCounts[_type], "Reached maxOfferCount");
        offerCounts[_type] ++;
        addedCounts[_type] ++;
        offers[_type][offerCounts[_type]] = _tokenId;
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);
        emit OfferAdded(_type);
    }

    function fillOffers(uint _type, uint _amount) public inProgress nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= whitelist[_type][msg.sender], "Insufficient claimable quota");
        require(offerCounts[_type] >= _amount, "Insufficient stock");
        require(paymentTokens[_type] != address(0), "ERC20 payment token is not set");
        require(unitPrices[_type]>0, "Unit price is not set");
        uint totalPrice = unitPrices[_type] * _amount;
        whitelist[_type][msg.sender] -= _amount;
        funds[_type] += totalPrice;
        IERC20(paymentTokens[_type]).safeTransferFrom(msg.sender, address(this), totalPrice);
        for(uint i = 1; i <= _amount; i ++){
            nftCollection.transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
        emit OfferFilled(_type, _amount, totalPrice, msg.sender);
    }

    function claimFund(uint _type) public onlyRole(CLAIM_FUND_ROLE) inPause nonReentrant {
        require(funds[_type] > 0, "There is no fund to be claimed");
        uint toTransfer = funds[_type];
        funds[_type] = 0;
        IERC20(paymentTokens[_type]).safeTransfer(msg.sender, toTransfer);
        emit FundClaimed();
    }

    function claimRemainingStock(uint _type, uint _amount) public onlyRole(CLAIM_STOCK_ROLE) inPause nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= offerCounts[_type], "Insufficient stock");
        for(uint i = 1; i <= _amount; i ++){
            nftCollection.transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
        emit RemainingStockClaimed();
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback () external {
        revert();
    }
}
