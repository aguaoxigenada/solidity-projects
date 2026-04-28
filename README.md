# solidity-projects

Solidity learning exercises and small contracts, built with [Foundry](https://book.getfoundry.sh/).

## Structure

```
src/
  factoryStorage/        # factory pattern playground
    SimpleStorage.sol    # base storage contract
    AddFiveStorage.sol   # extends SimpleStorage; adds 5 on store
    StorageFactory.sol   # deploys and interacts with SimpleStorage instances
test/
  factoryStorage/
    SimpleStorage.t.sol  # unit + fuzz tests
script/                  # forge scripts (deployments)
lib/                     # forge-installed dependencies (e.g. forge-std)
```

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`, `chisel`)
- Solidity `0.8.19` (pinned in `foundry.toml`)

Install Foundry:

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Common commands

```shell
forge build          # compile
forge test           # run tests
forge test -vvv      # verbose output (logs + traces on failure)
forge fmt            # format code
forge snapshot       # gas snapshot of tests
anvil                # local dev node
```

### Deploy (example)

```shell
forge script script/<Name>.s.sol:<NameScript> \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key> \
  --broadcast
```

## License

MIT
