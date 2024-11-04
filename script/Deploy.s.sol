// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "../src/ValueBadgeNFT.sol";

/**
 * To deploy this contract on Base Sepolia when key is already stored in cast:
 *   $ source .env
 *  $ forge script --chain sepolia script/Deploy.s.sol:DeployValueBadgeSepolia -account <mint account nickname in cast> --froms <mint account address> --rpc-url $RPC_BASE_SEPOLIA --broadcast --verify -vvvv
 */
contract DeployValueBadgeSepolia is Script {
    function run() external {
        vm.startBroadcast();

        ValueBadgeNFT valueBadgeNFT = new ValueBadgeNFT(vm.envAddress("CHAINLINK_ORACLE_USDETH_SEPOLIA"));

        vm.stopBroadcast();
    }
}

/**
 * To deploy this contract on Base mainnet when key is already stored in cast:
 *   $ source .env
 *  $ forge script --chain mainnet script/Deploy.s.sol:DeployValueBadgeSepolia -account <mint account nickname in cast> --froms <mint account address> --rpc-url $RPC_BASE_MAINNET --broadcast --verify -vvvv
 */
contract DeployValueBadgeMainnet is Script {
    function run() external {
        vm.startBroadcast();

        ValueBadgeNFT valueBadgeNFT = new ValueBadgeNFT(vm.envAddress("CHAINLINK_ORACLE_USDETH_MAINNET"));

        vm.stopBroadcast();
    }
}