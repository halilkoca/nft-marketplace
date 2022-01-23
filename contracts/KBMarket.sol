// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// security against transactions for multiple requests
import "hardhat/console.sol";

contract KBMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    // number of items minting, number of transactions,
    // tokens that have not been sold
    // keep track of tokens total number - tokenId
    // array need to know the length - help to keep track for arrays

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokenSold;

    // determine who is the owner of the contract
    // charge a listing fee so the owner makes a commission

    address payable owner;

    // we are deploying to MATIC
    // the API is the same so you can
    // use ether same as the MATIC
    // they both have 18 decimal
    // 0.045 in the cents
    uint256 listingPrice = 0.045 ether;

    constructor() {
        // set the owner
        owner = payable(msg.sender);
    }

    // structs can act like objects
    struct MarketToken {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // tokenId return which MarketToken
    // fetch which one it is
    mapping(uint256 => MarketToken) private idToMarketToken;

    // listen to events from front end applications
    event MarketTokenMinted(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    //get the listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // two functions to interact with contract
    // 1. create a market item to put it up for sale
    // 2. create a market sale for buying and selling between parties
    function mintMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        // nonReentrant is a modifier to prevent reentry attack

        require(price > 0, "Price must be at least one wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _tokenIds.increment();
        uint256 itemId = _tokenIds.current();

        // putting it up for sale - bool - no owner
        idToMarketToken[itemId] = MarketToken(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        // NFT Transaction
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    // function to conduct transactions and market sales
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketToken[itemId].price;
        uint256 tokenId = idToMarketToken[itemId].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to continue"
        );

        // transfer the amount to the seller
        idToMarketToken[itemId].seller.transfer(msg.value);

        // transfer the token from contract address to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketToken[itemId].owner = payable(msg.sender);
        _tokenSold.increment();

        payable(owner).transfer(listingPrice);
    }

    // function to fetchMarketItems
    // minting, buyinh and selling
    function fetchMarketTokens() public view returns (MarketToken[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _tokenSold.current();
        uint256 currentIndex = 0;

        // looping over the number of items created
        // (if number has not been sold populate the array)
        MarketToken[] memory items = new MarketToken[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketToken[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}