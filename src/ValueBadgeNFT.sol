// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @dev ValueBadgeNFT holds a snapshot of the value of ETH held on the minting wallet
 *
 * Contract deployment requires the address of the Chainlink oracle for ETHUSD, which differs by chain
 *
 * Expansion oppportunities
 * - use ERC721URIStorage to store a URI for an image
 * - require payment to mint NFT
 */
contract ValueBadgeNFT is ERC721, ERC721Burnable {
    uint256 public currentTokenId;
    uint256 public MAX_NFT_COUNT = 1000;

    uint256 private WEI_PER_ETH = 1e18;

    DataConsumerV3 internal priceFeed;

    /**
     * These could be handled by uint32 through uint128 values.  However, sizes other than uint256 can increase storage or gas in some cases.
     * Leaving optimization for later.
     */
    mapping(uint256 => uint256) public valueEth; // in WEI (ETH * 10^18)
    mapping(uint256 => uint256) public valueUsd; // in USD * 1E8
    mapping(uint256 => uint256) public dateStamp; // when NFT was generated

    event NewValueBadge(
        address indexed originalMinter,
        uint256 ethValue, // ETH value * 10^18
        uint256 centsValue, // ETH value in USD cents
        uint256 date // datestamp of block that minted this NFT
    );

    constructor(address oracleAddress) ERC721("ValueBadgeNFT", "VBNFT") {
        priceFeed = new DataConsumerV3(oracleAddress);
    }

    function safeMint(address to) public returns (uint256) {
        require(
            currentTokenId < MAX_NFT_COUNT,
            "Max mint count already reached"
        );
        _safeMint(to, ++currentTokenId);

        uint256 usdPrice = uint(priceFeed.getChainlinkDataFeedLatestAnswer()); // USD per ETH * 1e8
        uint256 usdValue = (msg.sender.balance * usdPrice) / WEI_PER_ETH;

        dateStamp[currentTokenId] = block.timestamp;
        valueEth[currentTokenId] = msg.sender.balance;
        valueUsd[currentTokenId] = usdValue;

        emit NewValueBadge(
            msg.sender,
            valueEth[currentTokenId],
            valueUsd[currentTokenId],
            dateStamp[currentTokenId]
        );

        return currentTokenId;
    }
}

/**
 * Connect to specified chainlink oracle and get latest price
 */
contract DataConsumerV3 {
    AggregatorV3Interface internal dataFeed;

    constructor(address feedAddress) {
        dataFeed = AggregatorV3Interface(feedAddress);
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (, int answer, , , ) = dataFeed.latestRoundData();
        return answer;
    }
}
