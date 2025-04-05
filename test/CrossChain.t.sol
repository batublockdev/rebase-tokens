// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interface/IRebaseToken.sol";
import {CCIPLocalSimulatorFork} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner");

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    Vault vault;

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();

        vm.makePersistent(address(ccipLocalSimulatorFork));

        // deploy and configure the sepolia token
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        vm.stopPrank();

        // deploy and configure the arb-sepolia token
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vm.stopPrank();
    }
}
