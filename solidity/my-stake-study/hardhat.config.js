require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require('hardhat-deploy');
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ethers");


module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY]
    },
    localhost: {
      url:"http://127.0.0.1:8545",
      chainId:31337,
      accounts:["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"],
      loggingEnabled: true, // 启用日志
    }
  },
  namedAccounts: {
    deployer: 0,
  },
};