const { deployments, upgrades, ethers } = require("hardhat");

async function main() {
    const MyToken = await ethers.getContractFactory("MyToken");
    const myTokenInstance = await MyToken.deploy();
    await myTokenInstance.waitForDeployment();
    const tokenAddress = await myTokenInstance.getAddress();

    console.log("MyToken deployed to:", tokenAddress);

    const startBlock = await ethers.provider.getBlockNumber();
    const endBlock = startBlock + 1000;
    const lockPeriod = ethers.parseUnits("100", 18); // 1000 blocks

    const MyStake = await ethers.getContractFactory("MyStake");
    console.log("Deploying MyStake...");
    const myStakeInstance = await upgrades.deployProxy(MyStake, [tokenAddress,startBlock,endBlock,lockPeriod], { initializer: 'initialize' });
    await myStakeInstance.waitForDeployment();
    const myStakeAddress= await myStakeInstance.getAddress()
    console.log("MyStake deployed to:",myStakeAddress);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });