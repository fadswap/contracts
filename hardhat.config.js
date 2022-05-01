/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('dotenv').config({path:__dirname+'/.env'})
require("@nomiclabs/hardhat-waffle");
//require('hardhat-exposed');
require('solidity-coverage');
require('hardhat-deploy');

const { MNEMONIC } = process.env

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      live: false,
      saveDeployments: true,
      tags: ["local"]
    },
    hardhat: {
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: {mnemonic: MNEMONIC}
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: {mnemonic: MNEMONIC}
    }
  },
  namedAccounts: {
    deployer: {
        default: 0,
    },
  },
};
