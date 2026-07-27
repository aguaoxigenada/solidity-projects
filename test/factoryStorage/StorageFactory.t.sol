// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// `Test`    -> Foundry's base test contract: assertions (assertEq, ...) + cheatcodes (vm.*)
// `console` -> lets us print during a test with console.log(...); shown with `forge test -vv`
import {Test, console} from "forge-std/Test.sol";
import {StorageFactory} from "../../src/factoryStorage/StorageFactory.sol";
import {SimpleStorage} from "../../src/factoryStorage/SimpleStorage.sol";

contract StorageFactoryTest is Test {
    StorageFactory factory;

    // Runs before EVERY test below, so each test starts from a fresh, empty factory.
    function setUp() public {
        factory = new StorageFactory();
    }

    // The factory should deploy a brand-new SimpleStorage and track it in its array.
    function test_CreateDeploysAndTracksAChild() public {
        factory.createSimpleStorageContract();

        // The public array getter takes an index and returns the child at that index.
        // If index 0 doesn't exist this call reverts, so simply getting an address proves
        // one child was created and stored.
        SimpleStorage child = factory.listOfSimpleStorageContracts(0);
        assertTrue(address(child) != address(0), "child should be a real deployed address");
    }

    // sfStore(index, number) should forward the value into the child, and sfGet should read it back.
    function test_SfStoreThenSfGetRoundTrips() public {
        factory.createSimpleStorageContract();

        factory.sfStore(0, 123); // write 123 into child #0
        uint256 got = factory.sfGet(0); // read it back through the factory

        assertEq(got, 123, "value written via the factory should be readable via the factory");
    }

    // Each createSimpleStorageContract() call deploys an INDEPENDENT contract with its own storage.
    // Writing to child #0 must not affect child #1.
    function test_ChildrenHaveIndependentStorage() public {
        factory.createSimpleStorageContract(); // index 0
        factory.createSimpleStorageContract(); // index 1

        factory.sfStore(0, 111);
        factory.sfStore(1, 222);

        assertEq(factory.sfGet(0), 111, "child 0 keeps its own value");
        assertEq(factory.sfGet(1), 222, "child 1 keeps its own value");
    }

    // Calling the child directly should agree with reading through the factory:
    // the factory just holds a reference to the same deployed contract.
    function test_FactoryAndDirectChildCallAgree() public {
        factory.createSimpleStorageContract();
        factory.sfStore(0, 77);

        SimpleStorage child = factory.listOfSimpleStorageContracts(0);
        assertEq(child.retrieve(), factory.sfGet(0), "direct read and factory read must match");
    }

    // Reading an index that was never created should revert (array out-of-bounds).
    // `vm.expectRevert()` asserts that the VERY NEXT call fails; the test passes only if it does.
    function test_SfGetOnMissingIndexReverts() public {
        vm.expectRevert();
        factory.sfGet(0); // no child created in this test -> out-of-bounds -> revert
    }

    // Fuzz test: Foundry runs this with ~256 random values of `_number`.
    // The round-trip property should hold for ANY input, not just the ones we picked.
    function testFuzz_SfStoreRoundTrips(uint256 _number) public {
        factory.createSimpleStorageContract();
        factory.sfStore(0, _number);
        assertEq(factory.sfGet(0), _number);
    }
}
