// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// `Script` gives you the broadcasting machinery (vm.startBroadcast / vm.stopBroadcast)
// and `console` for logging. Both come from forge-std.
import {Script, console} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/factoryStorage/SimpleStorage.sol";

// A deploy script is just a contract with a `run()` entrypoint.
// Run it with:  forge script script/DeploySimpleStorage.s.sol:DeploySimpleStorage ...
contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        // Everything between startBroadcast and stopBroadcast is turned into REAL
        // transactions and signed with the --private-key (or --account) you pass on the CLI.
        // Without --broadcast, forge only SIMULATES this (a free dry run).
        vm.startBroadcast();

        SimpleStorage simpleStorage = new SimpleStorage();

        vm.stopBroadcast();

        // Shows up in the script output; handy for grabbing the deployed address.
        console.log("SimpleStorage deployed at:", address(simpleStorage));
        return simpleStorage;
    }
}
