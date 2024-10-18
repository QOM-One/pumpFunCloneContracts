require('dotenv').config()
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",   
    settings: {
      optimizer: {
        enabled: true,   
        runs: 1000       
      }
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.SEPOLIA_URL || "https://site1.moralis-nodes.com/sepolia/35ba158e5655466f9e015f42c4bf6f63",
      },
      chainId: 11155111,
    }
  }
};
