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

npx hardhat init
npm install @openzeppelin/contracts
npm install @openzeppelin/contracts-upgradeable
npm install -D hardhat-deploy
npm install dotenv 安装dotenv使用配置文件
npm install @openzeppelin/hardhat-upgrades

部署 
npx hardhat ignition deploy ./ignition/modules/MetaNode.js
npx hardhat run scripts/deploy_mystake.js

执行测试
npx hardhat test test/mystake.js
