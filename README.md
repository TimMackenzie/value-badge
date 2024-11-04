## ValueBadge

This project is a demonstration of some introductory Solidity smart contract features using Foundry and Chainlink, and is tested on Base.

The ValueBadgeNFT contract allows a caller to create an NFT that captures the current ETH balance and the equivalent USD value based on current price.

Tests are instrumented to verify on Base Sepolia using known blocks and oracle values, as well as testing on Base mainnet.

Deployment scripts support multiple chains, but additional values will need to be added to `foundry.toml` and `.env` to support them.

## Usage

### Setup

This project has the following dependencies, which should be installed
- chainlink-brownie-contracts
- forge-std
- openzepplin-contracts

```shell
 $ forge install OpenZeppelin/openzeppelin-contracts --no-commit
 $ forge install smartcontractkit/chainlink-brownie-contracts --no-commit
```


### ENV

Setup the .env file similar to the following.  Note that the ETHERACAN variable contains an API key from basescan.org for Base.

```shell
RPC_BASE_SEPOLIA=https://base-sepolia.g.alchemy.com/v2/<your api key>
RPC_BASE_MAINNET=https://base-mainnet.g.alchemy.com/v2/<your api key>

CHAINLINK_ORACLE_USDETH_MAINNET=0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70
CHAINLINK_ORACLE_USDETH_SEPOLIA=0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1

ETHERSCAN_API_KEY=<your api key>
```

### Build

```shell
$ forge build
```

### Test

Note that because the tests explicitly select chains and blocks, the `--fork-url` and `--fork-block-number` arguments are not needed.  These tests are slower than local-only tests as they are downloading chaindata.

```shell
$ forge test
```

### Deploy

See `scripts/Deploy.s.sol` for details on deploying.  Script and command examples presume `cast` has been set up with a private key already.

### Cast

After deploying, grab the contract address.  Then testing can be done on the command line, e.g.

```shell
$ cast send <contract address> "safeMint(address)(uint256)" <caller address from saved credential> --account <your saved credential name> --rpc-url $RPC_BASE_SEPOLIA
$ cast call <contract address> "currentTokenId()" <caller address from saved credential> --account <your saved credential name> --rpc-url $RPC_BASE_SEPOLIA
```

### Test UI

The sample web page will submit the transaction to the address entered on the page.
- Deploy the contract and capture the address 
- Install metamask in target browser
- Select the correct network (e.g. Base Sepolia) in Metamask
- Open the browser's javascript console to view logs

Using a local web server avoids needing to adjust metamask settings to run on local files.

```shell
$ cd test
$ python3 -m http.server --bind localhost
```

Then, open the page
```shell
http://localhost:8000/TestMint.html
```

