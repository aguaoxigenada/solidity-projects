# solidity-projects

Solidity learning exercises and small contracts, built with [Foundry](https://book.getfoundry.sh/).

This README is written for someone coming from **Solana** who wants to learn Solidity and Foundry from scratch — how the EVM model differs, what Foundry actually does, how to test, and how to run a local dev net.

---

## Table of contents

1. [The big mental shift: Solana → EVM](#1-the-big-mental-shift-solana--evm)
2. [The contracts in this repo](#2-the-contracts-in-this-repo)
3. [What Foundry actually does](#3-what-foundry-actually-does)
4. [Project layout](#4-project-layout)
5. [Common commands (cheat sheet)](#5-common-commands-cheat-sheet)
6. [How the tests work](#6-how-the-tests-work)
7. [Your local dev net (anvil)](#7-your-local-dev-net-anvil)
8. [Deploying with a script](#8-deploying-with-a-script)
9. [Suggested learning path](#9-suggested-learning-path)

---

## 1. The big mental shift: Solana → EVM

On Solana, **code and state are separate**: a program is stateless, and data lives in
accounts you pass in. In the EVM, **each contract *is* an account that owns its own
storage** — the contract's variables live inside the contract itself. There is no
"pass in the account."

| Solana | EVM / Solidity | In this repo |
|--------|----------------|--------------|
| Program (stateless) + Accounts (state) | Contract = code **and** its own storage, together | `SimpleStorage` holds `myFavoriteNumber` inside itself |
| Rust + Anchor | Solidity | `.sol` files |
| `Pubkey` | `address` (20 bytes) | `StorageFactory` stores `SimpleStorage[]` addresses |
| Rent, account sizing upfront | Declare a variable and write to it; storage grows implicitly | `listOfPeople.push(...)` |
| CPI (cross-program invocation) | Call another contract like an object: `contract.method()` | `StorageFactory.sfStore` calls `.store()` on a child |
| Deploy program, then init accounts | `new SimpleStorage()` deploys a fresh contract on the fly | `createSimpleStorageContract()` |
| lamports | `wei` (1 ETH = 10^18 wei) | — |
| Anchor tests in TypeScript | **Tests are written in Solidity itself** (Foundry) | `SimpleStorage.t.sol` |

The last row is the pleasant surprise: with Foundry you write tests in Solidity, not
JS/TS — no client SDK ceremony.

Two more distinctions worth burning in:

- **`view`/read calls are free.** Reading state off-chain costs no gas and sends no
  transaction (like a Solana RPC read). Only state-*changing* calls cost gas.
- **Tests don't need a running node.** Foundry runs its own in-memory EVM, so
  `forge test` is instant and isolated. You only need a node (`anvil`) when you want to
  simulate a real deployment.

---

## 2. The contracts in this repo

All under `src/factoryStorage/`.

### `SimpleStorage.sol` — the fundamentals in one file
```solidity
uint256 myFavoriteNumber;                          // storage variable: permanent, on-chain, costs gas to change
struct Person { uint256 favoriteNumber; string name; }
Person[] public listOfPeople;                      // dynamic array in storage; `public` auto-generates a getter
mapping(string => uint256) public nameToFavoriteNumber; // hash map (no length, not iterable)

function store(uint256 _n) public virtual { myFavoriteNumber = _n; } // writes state; `virtual` = overridable
function retrieve() public view returns (uint256) { return myFavoriteNumber; } // `view` = read-only, free off-chain
```

### `AddFiveStorage.sol` — inheritance
```solidity
contract AddFiveStorage is SimpleStorage {         // inherits everything
    function store(uint256 _n) public override {   // replaces parent's store (allowed because it was `virtual`)
        myFavoriteNumber = _n + 5;                 // stores n + 5 instead of n
    }
}
```

### `StorageFactory.sol` — the factory pattern
```solidity
SimpleStorage[] public listOfSimpleStorageContracts;

function createSimpleStorageContract() public {    // `new` deploys a fresh contract FROM a contract
    listOfSimpleStorageContracts.push(new SimpleStorage());
}
function sfStore(uint256 i, uint256 n) public {    // reach into a deployed child and call it (EVM's version of a CPI)
    listOfSimpleStorageContracts[i].store(n);
}
function sfGet(uint256 i) public view returns (uint256) {
    return listOfSimpleStorageContracts[i].retrieve();
}
```

---

## 3. What Foundry actually does

Foundry is a toolkit of four binaries. Think of it as your compiler + test runner +
localnet + CLI wallet, all in one.

| Binary | What it is | Solana analogy |
|--------|-----------|----------------|
| **`forge`** | Compiles contracts, runs tests, deploys. Your main tool. | `anchor build` / `anchor test` |
| **`anvil`** | A local dev blockchain you run on your machine. | `solana-test-validator` |
| **`cast`** | CLI to send transactions and read chain state. | `solana` CLI |
| **`chisel`** | A Solidity REPL for quick experiments. | — |

**What happens when you run `forge test`:**
1. `forge` compiles every `.sol` file in `src/` and `test/` with the pinned `solc` (0.8.19).
2. For each test contract it spins up a **fresh in-memory EVM** (no node needed).
3. It runs `setUp()`, then every `function test_*` / `testFuzz_*`, each in an isolated state.
4. It reports pass/fail plus gas used. On failure with `-vvv`, it prints a full call trace.

That in-memory EVM is why testing is instant and why you don't need `anvil` for tests.
`anvil` is only for when you want a *persistent* node to deploy to and poke at with `cast`.

Configuration lives in [`foundry.toml`](./foundry.toml): source/test/lib paths, the
`solc` version, the optimizer, and formatting rules. Dependencies are installed into
`lib/` (like `node_modules`); `forge-std` is Foundry's standard library for testing.

---

## 4. Project layout

```
src/
  factoryStorage/        # factory pattern playground
    SimpleStorage.sol    # base storage contract
    AddFiveStorage.sol   # extends SimpleStorage; adds 5 on store
    StorageFactory.sol   # deploys and interacts with SimpleStorage instances
test/
  factoryStorage/
    SimpleStorage.t.sol      # unit + fuzz tests for SimpleStorage / AddFiveStorage
    StorageFactory.t.sol     # tests for the factory pattern
script/                  # forge deployment scripts
lib/
  forge-std/             # Foundry standard library (Test, console, cheatcodes)
out/                     # compiled artifacts (gitignored)
cache/                   # forge build cache (gitignored)
foundry.toml             # Foundry configuration
```

Conventions: tests end in `.t.sol`, scripts end in `.s.sol`.

---

## 5. Common commands (cheat sheet)

### Setup
```shell
curl -L https://foundry.paradigm.xyz | bash   # install foundryup
foundryup                                      # install/update forge, cast, anvil, chisel
forge install foundry-rs/forge-std             # add a dependency into lib/
```

### Build & format
```shell
forge build                # compile everything
forge fmt                  # auto-format all .sol files
forge fmt --check          # verify formatting (CI-friendly, no changes)
```

### Test
```shell
forge test                 # run all tests
forge test -vv             # + show console.log output
forge test -vvv            # + show call traces for failing tests
forge test -vvvv           # + show traces for ALL tests (very verbose)
forge test --match-test test_AddFive          # run tests matching a name
forge test --match-contract StorageFactory    # run one test contract
forge test --match-path test/**/StorageFactory.t.sol
forge snapshot             # write gas usage per test to .gas-snapshot
forge coverage             # test coverage report
```

### Inspect
```shell
forge inspect SimpleStorage abi        # print a contract's ABI
forge inspect SimpleStorage bytecode   # print bytecode
chisel                                 # open a Solidity REPL
```

### Local node & interaction (see sections 7–8)
```shell
anvil                                          # start a local dev chain
cast send   <addr> "store(uint256)" 42 ...     # send a state-changing tx (costs gas)
cast call   <addr> "retrieve()(uint256)" ...   # read state (free, no tx)
cast balance <addr> --rpc-url http://127.0.0.1:8545
```

---

## 6. How the tests work

Open [`test/factoryStorage/SimpleStorage.t.sol`](./test/factoryStorage/SimpleStorage.t.sol).
The pattern:

- The test contract inherits `Test` — that gives you assertions and **cheatcodes** (the
  `vm.*` functions).
- `setUp()` runs **before every test**, giving each test fresh contracts and isolated
  state (like `beforeEach`).
- Any `function test_*()` is a test. `assertEq(a, b)` fails the test if `a != b`.
  Other assertions: `assertTrue`, `assertGt`, `assertLt`, `assertEq` for many types.
- `function testFuzz_*(uint256 x)` is a **fuzz test** — Foundry auto-generates ~256
  random inputs for `x` and runs the body for each. Free property-based testing.

**Useful cheatcodes** (from `forge-std`):

| Cheatcode | Does |
|-----------|------|
| `vm.prank(addr)` | Make the **next** call come from `addr` (spoof `msg.sender`) |
| `vm.startPrank(addr)` / `vm.stopPrank()` | Spoof sender for a block of calls |
| `vm.expectRevert()` | Assert the next call reverts (fails) |
| `vm.expectRevert(bytes)` | Assert it reverts with a specific error |
| `vm.deal(addr, amount)` | Set an address's ETH balance |
| `vm.warp(timestamp)` / `vm.roll(block)` | Fast-forward time / block number |
| `console.log(...)` | Print during a test (needs `import {console} from "forge-std/console.sol";`) |

Run it:
```shell
forge test -vv
```
Then intentionally break an assertion (e.g. expect `16` instead of `15`) and rerun with
`forge test -vvv` to see how failures and traces look.

---

## 7. Your local dev net (anvil)

`anvil` is your localnet — the EVM equivalent of `solana-test-validator`.

Open a **second terminal** and run:
```shell
anvil
```
It boots an instant local chain, prints 10 pre-funded accounts (address + private key),
and listens on `http://127.0.0.1:8545`. Leave it running.

> The private keys anvil prints are **well-known and public** — they exist on every
> anvil instance. Never use them on a real network.

Then, from your first terminal, deploy and interact with `cast`
(anvil's first default account is used below):

```shell
# 1. Deploy SimpleStorage to the local node
forge create src/factoryStorage/SimpleStorage.sol:SimpleStorage \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
# -> prints "Deployed to: 0x..."   (copy that address)

# 2. store(42) — a state-changing transaction (costs gas)
cast send <DEPLOYED_ADDRESS> "store(uint256)" 42 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 3. retrieve() — a read (free, no transaction). Should print 42.
cast call <DEPLOYED_ADDRESS> "retrieve()(uint256)" --rpc-url http://127.0.0.1:8545
```

The `send` vs `call` split is the EVM's version of "transaction vs RPC read":
`cast send` changes state and costs gas; `cast call` only reads and is free.

---

## 8. Deploying with a script

For anything beyond a one-off, write a deploy script in `script/` (ends in `.s.sol`)
instead of long `cast` commands. A minimal example:

```solidity
// script/DeploySimpleStorage.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/factoryStorage/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        vm.startBroadcast();              // everything between here and stop is sent as real txs
        SimpleStorage s = new SimpleStorage();
        vm.stopBroadcast();
        return s;
    }
}
```

Run it against anvil:
```shell
forge script script/DeploySimpleStorage.s.sol:DeploySimpleStorage \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```
Without `--broadcast` it only simulates (a dry run) — handy for checking gas and logic
before spending anything.

---

## 9. Suggested learning path

1. `forge test -vvv`, then intentionally break an assertion to learn the failure output.
2. Read [`test/factoryStorage/StorageFactory.t.sol`](./test/factoryStorage/StorageFactory.t.sol)
   to see the factory pattern tested end to end.
3. Learn cheatcodes: `vm.prank`, `vm.expectRevert`, `console.log`.
4. Write and run a deploy script against `anvil` (section 8).
5. Add a revert path to a contract (e.g. `require(...)`) and test it with `vm.expectRevert`.

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`, `chisel`)
- Solidity `0.8.19` (pinned in `foundry.toml`)

## License

MIT
