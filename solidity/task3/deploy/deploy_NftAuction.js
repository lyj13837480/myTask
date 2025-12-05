const { deployments, upgrades, ethers } = require("hardhat");
const path = require("path");
const fs = require("fs");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    const nftAuction = await ethers.getContractFactory('NftAuction');

    console.log("部署用户地址：", deployer);
    const nftAuctionAdd = await upgrades.deployProxy(nftAuction, [], { initializer: 'initialize' });
    await nftAuctionAdd.waitForDeployment();

    const proxyAddress = await nftAuctionAdd.getAddress();
    console.log("代理合约地址：", proxyAddress);
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("实现合约地址：", implAddress);

    const storePath = path.resolve(__dirname, "proxyNftAuction.json");

    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress,
            implAddress,
            abi: nftAuction.interface.format("json"),
        })
    );

    await save("NftAuction", {
        abi: nftAuction.interface.format("json"),
        address: nftAuctionAdd.getAddress(),
        // args: [],
        // log: true,
    })
};

module.exports.tags = ['deployNftAuction'];