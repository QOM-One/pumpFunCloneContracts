require('dotenv').config()
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: "https://site1.moralis-nodes.com/sepolia/35ba158e5655466f9e015f42c4bf6f63",
      },
      chainId: 11155111,
    }
  }
};
