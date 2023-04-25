// SPDX-License-Identifier: MIT

/*

      .oooo.               oooooo     oooo           oooo                      o8o                       
     d8P'`Y8b               `888.     .8'            `888                      `"'                       
    888    888 oooo    ooo   `888.   .8'    .oooo.    888   .ooooo.  oooo d8b oooo  oooo  oooo   .oooo.o 
    888    888  `88b..8P'     `888. .8'    `P  )88b   888  d88' `88b `888""8P `888  `888  `888  d88(  "8 
    888    888    Y888'        `888.8'      .oP"888   888  888ooo888  888      888   888   888  `"Y88b.  
    `88b  d88'  .o8"'88b        `888'      d8(  888   888  888    .o  888      888   888   888  o.  )88b 
     `Y8bd8P'  o88'   888o       `8'       `Y888""8o o888o `Y8bod8P' d888b    o888o  `V88V"V8P' 8""888P' 

*/

pragma solidity 0.8.17;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

contract EnglishAuction {
    // Events
    event Bid(address indexed bidder, uint256 amount);

    address payable public immutable seller;
    uint256 public immutable duration;
    uint256 public immutable startAt;
    uint256 public immutable endAt;
    uint256 public immutable reservePrice;

    IERC721 public immutable nft;
    uint256 public immutable tokenId;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;

    constructor(uint256 _duration, uint256 _startAt, uint256 _reservePrice, address _nft, uint256 _tokenId) {
        require(_duration > 0, "EnglishAuction: duration must be greater than 0.");
        require(_startAt > block.timestamp, "EnglishAuction: startAt must be in the future.");
        require(_nft != address(0), "EnglishAuction: nft cannot be the zero address.");

        seller = payable(msg.sender);
        duration = _duration;
        startAt = _startAt;
        endAt = _startAt + _duration;
        reservePrice = _reservePrice;
        nft = IERC721(_nft);
        tokenId = _tokenId;
    }

    function isEscrowed() public view returns (bool) {
        return nft.ownerOf(tokenId) == address(this);
    }

    function bid() external payable {
        require(block.timestamp >= startAt, "EnglishAuction: auction has not started yet.");
        require(block.timestamp <= endAt, "EnglishAuction: auction has already ended.");
        require(isEscrowed(), "EnglishAuction: NFT is not escrowed.");
        require(msg.value >= reservePrice, "EnglishAuction: bid must be greater than reserve price.");
        require(msg.value > highestBid, "EnglishAuction: bid must be greater than highest bid.");
        require(msg.sender != seller, "EnglishAuction: seller cannot bid.");

        highestBid = msg.value;
        highestBidder = msg.sender;
        bids[msg.sender] += msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function claim() external {
        require(block.timestamp > endAt, "EnglishAuction: auction has not ended yet.");
        require(isEscrowed(), "EnglishAuction: NFT is not escrowed.");
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, tokenId);
            (bool success,) = seller.call{value: highestBid}("");
            require(success, "EnglishAuction: failed to send highest bid to seller.");
        } else {
            nft.transferFrom(address(this), seller, tokenId);
        }
    }

    function withdraw() external {
        require(msg.sender != highestBidder, "EnglishAuction: highest bidder cannot withdraw.");
        require(bids[msg.sender] > 0, "EnglishAuction: no bid to withdraw.");

        uint256 bidAmount = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: bidAmount}("");
        require(success, "EnglishAuction: failed to send bid amount to bidder.");
    }
}
