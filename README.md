# Advanced Sample Hardhat Project


liquidity: 0x832E744d07f8f8aC572E449f5Bbe8FeA4fE699ae  https://rinkeby.etherscan.io/address/0x832e744d07f8f8ac572e449f5bbe8fea4fe699ae#code

XXXCoin: 0xc2C003D4fc03574D493d1fDe29766B016842D67f  https://rinkeby.etherscan.io/address/0xc2c003d4fc03574d493d1fde29766b016842d67f#code

Staking: https://rinkeby.etherscan.io/address/0x059ac5deefc1664ce906f11ac11eb9a7976b499e#code

DAO(verification pending): https://rinkeby.etherscan.io/address/0x62bc08dda957ef675e8c33cf92fc2fbcf330518b#code

ACDM Token: 0x30B51e0EEF36af1c3c3aE525035F9E27Cc7Bf314 https://rinkeby.etherscan.io/address/0x30b51e0eef36af1c3c3ae525035f9e27cc7bf314#code

ACDM Platform: 


Adding Liqudity to XXX / ETH pair on Uniswap: https://rinkeby.etherscan.io/tx/0x25ef08c39d515de63e46aa45a1f339951fa7a17903ae2c30109f7111f53b63a7

///


This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
