// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTOffering is AccessControl, ReentrancyGuard {
    mapping(uint => bool) public supportedTypes;                 // Map from NFT type to supported status
    mapping(uint => uint) public maxOfferCounts;                 // Map from NFT type to max # NFTs to be added
    mapping(uint => uint) public addedCounts;                    // Map from NFT type to # NFTs already added
    mapping(uint => uint) public offerCounts;                    // Map from NFT type to index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type.
    mapping(uint => mapping(uint => uint)) public offers;        // Map from NFT type to offerId-to-tokenId mapping
    mapping(uint => uint) public unitPrices;                     // Map from NFT type to unit price(Wei).
    uint public fund;                                            // Accumulated fund collected
    IERC721 nftCollection;                                       // The supported NFT collection
    bool private paused = true;                                  // If the claiming is paused
    mapping(uint => mapping(address => uint)) public whitelist;  // Map from NFT type to address-to-claimable-amount mapping

    bytes32 public constant MAKE_OFFER_ROLE = keccak256("MAKE_OFFER_ROLE");    // Role that can add item to the offering
    bytes32 public constant CLAIM_FUND_ROLE = keccak256("CLAIM_FUND_ROLE");    // Role that can claim the collected fund
    bytes32 public constant CLAIM_STOCK_ROLE = keccak256("CLAIM_STOCK_ROLE");  // Role that can claim the remaining NFTs

    constructor(address _nftCollection) {
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

    function setSupportedType(uint _type, bool _supported) public onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedTypes[_type] = _supported;
    }

    function setMaxOfferCount(uint _type, uint _maxCount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supportedTypes[_type], "NFT type not supported");
        maxOfferCounts[_type] = _maxCount;
    }

    function setUnitPrice(uint _type, uint _unitPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supportedTypes[_type], "NFT type not supported");
        unitPrices[_type] = _unitPrice;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = true;
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = false;
    }

    function addWhitelist(uint _type, address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supportedTypes[_type], "NFT type not supported");
        whitelist[_type][_whitelisted] = _claimable;
    }

    function addOffer(uint _type, uint _tokenId) public onlyRole(MAKE_OFFER_ROLE) inPause nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(addedCounts[_type] < maxOfferCounts[_type], "Reached maxOfferCount");
        offerCounts[_type] ++;
        addedCounts[_type] ++;
        offers[_type][offerCounts[_type]] = _tokenId;
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);
    }

    function fillOffers(uint _type, uint _amount) public payable inProgress nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= whitelist[_type][msg.sender], "Insufficient claimable quota");
        require(offerCounts[_type] - _amount >= 0, "Insufficient stock");
        require(msg.value == unitPrices[_type] * _amount, "The transaction value should match with the total price");
        whitelist[_type][msg.sender] -= _amount;
        fund += msg.value;
        for(uint i = 1; i <= _amount; i ++){
            nftCollection.transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
    }

    function claimFund() public onlyRole(CLAIM_FUND_ROLE) nonReentrant {
        require(fund > 0, "There is no fund to be claimed");
        uint toTransfer = fund;
        fund = 0;
        payable(msg.sender).transfer(toTransfer);
    }

    function claimRemainingStock(uint _type, uint _amount) public onlyRole(CLAIM_STOCK_ROLE) nonReentrant {
        require(supportedTypes[_type], "NFT type not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= offerCounts[_type], "Insufficient stock");
        for(uint i = 1; i <= _amount; i ++){
            nftCollection.transferFrom(address(this), msg.sender, offers[_type][offerCounts[_type]]);
            offerCounts[_type] --;
        }
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback () external {
        revert();
    }
}
