require('@nomicfoundation/hardhat-toolbox');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-gas-reporter');
require('dotenv').config();
require('solidity-coverage');

const { PRIVATE_KEY, POLYGON_API_KEY, POLYGON_RPC_URL } = process.env;

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(process.env.POLYGON_RPC_URL);
  }
});

module.exports = {
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter: {
    currency: 'MATIC',
    gasPrice: 21,
  },
  plugins: ['solidity-coverage'],

  networks: {
    hardhat: {},
    polygonMainnet: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/_ULp5HCwK_YWhB3OfsvTU64A8G9A0KsY',
      account: [PRIVATE_KEY],
    },

    polygonTestnet: {
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: POLYGON_API_KEY,
  },
  gasReporter: {
    currency: 'USD',
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: './contracts',
  },
};
