# 🖼️ 🎨 NFT Auction Contracts

This repository contains two types of NFT auction smart contracts written in Solidity, Dutch Auction and English style auction.

## 🇳🇱 Dutch Auction

In a Dutch Auction, the auction starts with a high initial price which gradually decreases over time. Bidders can place a bid at any point during the auction, and the first bidder who accepts the current price wins the auction.

## 🇬🇧 English Auction

In an English style auction, bidders place successively higher bids until no higher bid is made before the auction duration ends. The highest bidder at the end of the auction wins the item.

## :wrench: Development Tools

- **Solidity**: I've used Solidity version **0.8.13** to write the smart contracts in this repository.
- **Foundry**: a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

## :open_file_folder: Repository Structure

- `src/`: Contains the DutchAuction, EnglishAuction and MockERC721 smart contracts.
- `tests/`: Contains the test suite for the smart contracts using Foundry.

## :rocket: Getting Started

1. Clone this repository. `git clone https://github.com/0xValerius/auctions-contracts.git`
2. Install the required dependencies. `npm install`
3. Compile the smart contracts. `forge build`
4. Run the test suite. `forge test`

## :scroll: License

[MIT](https://choosealicense.com/licenses/mit/)
