# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```
1、npx hardhat --init 初始化hardhat项目
2、npm install @openzeppelin/contracts 安装openzeppelin合约
3、npm install @chainlink/contracts 安装chainlink合约
4、npm install dotenv 安装dotenv使用配置文件
5、npm install -D hardhat-deploy 安装hardhat-deploy 模块
6、npx hardhat deploy --tags MyERC20 --network sepolia 部署MyERC20合约
7、npx hardhat deploy --tags MyERC20 --network sepolia --reset 重新部署MyERC20合约
8、npm install @openzeppelin/hardhat-upgrades 
9、npm install --save-dev @nomicfoundation/hardhat-ethers@hh2 ethers
