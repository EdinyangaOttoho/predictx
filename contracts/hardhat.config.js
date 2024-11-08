require("@nomiclabs/hardhat-waffle");

require('dotenv').config();

const endpointUrl = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    compilers: [
      {
        version: `0.8.27`,
        settings: {
          optimizer: {
            enabled: true,
            runs: 50
          },
          evmVersion: `cancun`,
        }
      },
    ],
  },
  networks: {
    "taiko-holesky": {
      url: endpointUrl,
      accounts: [privateKey],
    },
  },
  paths: {
    sources: "./src"
  },
};