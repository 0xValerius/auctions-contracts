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

contract DutchAuction {
    address payable public immutable seller;
    uint256 public immutable duration;
    uint256 public immutable startAt;
    uint256 public immutable endAt;
    uint256 public immutable startPrice;
    uint256 public immutable minPrice;

    IERC721 public immutable nft;
    uint256 public immutable tokenId;

    constructor(
        uint256 _duration,
        uint256 _startAt,
        uint256 _startPrice,
        uint256 _minPrice,
        address _nft,
        uint256 _tokenId
    ) {
        require(_startPrice > _minPrice, "DutchAuction: startPrice must be greater than minPrice.");
        require(_startAt > block.timestamp, "DutchAuction: startAt must be in the future.");
        require(_startAt + _duration > block.timestamp, "DutchAuction: endAt must be in the future.");
        require(_nft != address(0), "DutchAuction: nft cannot be the zero address.");
        require(_minPrice > 0, "DutchAuction: minPrice must be greater than 0.");
        require(_minPrice < _startPrice, "DutchAuction: minPrice must be less than startPrice.");

        seller = payable(msg.sender);
        duration = _duration;
        startAt = _startAt;
        endAt = _startAt + _duration;
        startPrice = _startPrice;
        minPrice = _minPrice;
        nft = IERC721(_nft);
        tokenId = _tokenId;
    }

    function getPrice() public view returns (uint256) {
        require(block.timestamp >= startAt, "DutchAuction: auction has not started yet.");
        require(block.timestamp <= endAt, "DutchAuction: auction has already ended.");
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");

        // DiscountRate = (startPrice - minPrice) / duration
        return startPrice - ((startPrice - minPrice) * (block.timestamp - startAt)) / duration;
    }

    // Return if the auctioned NFT is escrowed by this contract.
    function isEscrowed() public view returns (bool) {
        return nft.ownerOf(tokenId) == address(this);
    }

    function bid() external payable {
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");
        require(msg.sender != seller, "DutchAuction: seller cannot bid.");
        require(block.timestamp >= startAt, "DutchAuction: auction has not started yet.");
        require(block.timestamp <= endAt, "DutchAuction: auction has already ended.");
        require(msg.value >= getPrice(), "DutchAuction: msg.value must be greater than or equal to current price.");

        uint256 currentPrice = getPrice();

        // Transfer ETH to seller.
        (bool sellerPayment,) = seller.call{value: currentPrice}("");
        require(sellerPayment, "DutchAuction: ETH seller payment failed.");

        // Transfer NFT to buyer.
        nft.transferFrom(address(this), msg.sender, tokenId);

        // Refund excess ETH to buyer.
        if (msg.value > currentPrice) {
            (bool refund,) = payable(msg.sender).call{value: msg.value - currentPrice}("");
            require(refund, "DutchAuction: ETH refund failed.");
        }
    }

    function noSale() external {
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");
        require(msg.sender == seller, "DutchAuction: only seller can call this function.");
        require(block.timestamp > endAt, "DutchAuction: auction has not ended yet.");

        // Transfer the NFT back to the seller.
        nft.transferFrom(address(this), msg.sender, tokenId);
    }
}
