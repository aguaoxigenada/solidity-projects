# solidity-projects

A collection of Solidity learning exercises and small contracts.

## Structure

- `factoryStorage/` — factory pattern playground
  - `SimpleStorage.sol` — base storage contract (number + people mapping)
  - `AddFiveSotrage.sol` — extends `SimpleStorage` to add 5 on store
  - `StorageFactory.sol` — deploys and interacts with `SimpleStorage` instances

## Requirements

- Solidity `0.8.19`
- A toolchain such as [Foundry](https://book.getfoundry.sh/) or [Hardhat](https://hardhat.org/), or [Remix](https://remix.ethereum.org/) for quick experiments.

## Usage

Open the contracts in Remix, or compile with your preferred toolchain:

```bash
# Foundry
forge build

# Hardhat
npx hardhat compile
```

## License

MIT
