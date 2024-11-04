// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/ValueBadgeNFT.sol";

contract ValueBadgeNFTTest is Test {
    // Sepolia blocks with associated ETH/USD values from Chainlink
    uint256 BLOCK_X = 17381090;
    uint256 ETH_PRICE_AT_BLOCK_X = 250750600000;
    uint256 BLOCK_Y = 17381222;
    uint256 ETH_PRICE_AT_BLOCK_Y = 250984268900;
    uint256 BLOCK_Z = 17380000; // starting block for fuzz test,  no ETH price stored in these tests

    ValueBadgeNFT public valueBadgeContract;

    address user1 = makeAddr("user1");

    /**
     * Default setup is for Sepolia tests
     */
    function setUp() public {
        valueBadgeContract = new ValueBadgeNFT(
            vm.envAddress("CHAINLINK_ORACLE_USDETH_SEPOLIA")
        );
        setUpSepolia();
    }

    /**
     * Setting the fork and block programmatically is more flexible than from the command line.
     * The downside is that we lose the time savings from cached blocks when using --fork-block-number
     * The following is similar to:
     *  forge test --fork-url <rpc_url> --fork-block-number <block number>
     */
    function setUpSepolia() public {
        string memory rpcBaseSepolia = vm.envString("RPC_BASE_SEPOLIA");
        uint256 forkId = vm.createFork(rpcBaseSepolia);
        vm.selectFork(forkId);

        vm.rollFork(BLOCK_X);
    }

    function setUpMainnet() public {
        string memory rpcBaseSepolia = vm.envString("RPC_BASE_MAINNET");
        uint256 forkId = vm.createFork(rpcBaseSepolia);
        vm.selectFork(forkId);
    }

    function testMint_noFunds() public {
        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(valueBadgeContract.valueEth(tokenId), 0, "wrong valueEth");
        assertEq(valueBadgeContract.valueUsd(tokenId), 0, "wrong valueUsd");
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    function testMint_withValue_1() public {
        vm.deal(user1, 2 ether); // 2 * 1e18
        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(block.number, BLOCK_X, "wrong block");

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(
            valueBadgeContract.valueEth(tokenId),
            2 * 1e18,
            "wrong valueEth"
        );
        assertEq(
            valueBadgeContract.valueUsd(tokenId),
            2 * ETH_PRICE_AT_BLOCK_X,
            "wrong valueUsd"
        );
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    function testMint_withValue_2() public {
        assertEq(block.number, BLOCK_X, "wrong intital block");

        vm.rollFork(BLOCK_Y);

        assertEq(block.number, BLOCK_Y, "wrong block after roll");

        vm.deal(user1, 3 ether); // 3 * 1e18
        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(
            valueBadgeContract.valueEth(tokenId),
            3 * 1e18,
            "wrong valueEth"
        );
        assertEq(
            valueBadgeContract.valueUsd(tokenId),
            3 * ETH_PRICE_AT_BLOCK_Y,
            "wrong valueUsd"
        );
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    function test_wrong_token() public {
        vm.deal(user1, 2 ether); // 2 * 1e18
        vm.prank(user1);
        valueBadgeContract.safeMint(user1);

        uint256 wrongTokenId = 123;
        assertEq(
            valueBadgeContract.valueEth(wrongTokenId),
            0,
            "wrong valueEth"
        );
        assertEq(
            valueBadgeContract.valueUsd(wrongTokenId),
            0,
            "wrong valueUsd"
        );
        assertEq(
            valueBadgeContract.dateStamp(wrongTokenId),
            0,
            "wrong dateStamp"
        );
    }

    function test_mintMax() public {
        vm.deal(user1, 2 ether); // 2 * 1e18

        // mint the max count of NFTs, matching 1-based index of tokens
        for (uint256 i = 1; i <= 1000; i++) {
            vm.prank(user1);
            valueBadgeContract.safeMint(user1);
        }

        // 1k already reached, this will fail
        vm.prank(user1);
        vm.expectRevert(bytes("Max mint count already reached"));
        valueBadgeContract.safeMint(user1);
    }

    /**
     * @param cycleCount number of NFTs to mint before the test. Use uint8 to prevent passing max mint count
     */
    function testFuzz_mintCount(uint8 cycleCount) public {
        vm.deal(user1, 2 ether); // 2 * 1e18

        // mint a bunch of NFTs
        for (uint8 i = 0; i < cycleCount; i++) {
            vm.prank(user1);
            valueBadgeContract.safeMint(user1);
        }

        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(tokenId, uint256(cycleCount) + 1, "Wrong first token ID");
        assertEq(
            valueBadgeContract.valueEth(tokenId),
            2 * 1e18,
            "wrong valueEth"
        );
        assertEq(
            valueBadgeContract.valueUsd(tokenId),
            2 * ETH_PRICE_AT_BLOCK_X,
            "wrong valueUsd"
        );
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    /**
     * @param startingBalance limited to uint128 to ensure we don't overflow multiplication; this is still larger than the maximum amount of wei available
     */
    function testFuzz_userBalance(uint128 startingBalance) public {
        vm.deal(user1, startingBalance); // in wei

        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        uint256 usdVal = (startingBalance * ETH_PRICE_AT_BLOCK_X) / 1e18;

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(
            valueBadgeContract.valueEth(tokenId),
            startingBalance,
            "wrong valueEth"
        );
        assertEq(
            valueBadgeContract.valueUsd(tokenId),
            usdVal,
            "wrong valueUsd"
        );
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    function testFuzz_block(uint8 blockCount) public {
        uint256 blockNumber = BLOCK_Z + blockCount;
        vm.rollFork(blockNumber);

        vm.deal(user1, 22 ether);

        vm.prank(user1);
        uint256 tokenId = valueBadgeContract.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(
            valueBadgeContract.valueEth(tokenId),
            22 * 1e18,
            "wrong valueEth"
        );
        assertNotEq(
            valueBadgeContract.valueUsd(tokenId),
            0,
            "valueUsd should not be zero"
        );
        assertEq(
            valueBadgeContract.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }

    /**
     * Simple demonstration of using the mainnet fork.  For an actual production contract, more mainnet testing should be done.
     */
    function test_mainnet() public {
        setUpMainnet();

        ValueBadgeNFT valueBadgeContractMain = new ValueBadgeNFT(
            vm.envAddress("CHAINLINK_ORACLE_USDETH_MAINNET")
        );

        vm.deal(user1, 19 ether);

        vm.prank(user1);
        uint256 tokenId = valueBadgeContractMain.safeMint(user1);

        uint256 dateStamp = vm.getBlockTimestamp();

        assertEq(tokenId, 1, "Wrong first token ID");
        assertEq(
            valueBadgeContractMain.valueEth(tokenId),
            19 * 1e18,
            "wrong valueEth"
        );
        assertNotEq(
            valueBadgeContractMain.valueUsd(tokenId),
            0,
            "valueUsd should not be zero"
        );
        assertEq(
            valueBadgeContractMain.dateStamp(tokenId),
            dateStamp,
            "wrong dateStamp"
        );
    }
}
