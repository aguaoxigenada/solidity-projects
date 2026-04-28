// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage} from "../../src/factoryStorage/SimpleStorage.sol";
import {AddFiveStorage} from "../../src/factoryStorage/AddFiveStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage simple;
    AddFiveStorage addFive;

    function setUp() public {
        simple = new SimpleStorage();
        addFive = new AddFiveStorage();
    }

    function test_StoreAndRetrieve() public {
        simple.store(42);
        assertEq(simple.retrieve(), 42);
    }

    function test_AddPersonUpdatesMapping() public {
        simple.addPerson("alice", 7);
        assertEq(simple.nameToFavoriteNumber("alice"), 7);
    }

    function test_AddFiveOverridesStore() public {
        addFive.store(10);
        assertEq(addFive.retrieve(), 15);
    }

    function testFuzz_StoreAndRetrieve(uint256 x) public {
        simple.store(x);
        assertEq(simple.retrieve(), x);
    }
}
