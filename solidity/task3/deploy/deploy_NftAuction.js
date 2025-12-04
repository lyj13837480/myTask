const { deployments, upgrades, ethers } = require("hardhat");
const { path } = require('path');

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    const nftAuction = ethers.getContractFactory('NftAuction');

    const nftAuctionAdd = await upgrades.deployProxy(nftAuction, [deployer], { initializer: 'initialize' });
    await nftAuctionAdd.waitForDeployment();

    const NftAuctionProxy = ethers.getContractFactory('NftAuctionProxy');

    const nftAuctionProxy = await upgrades.deployProxy(NftAuctionProxy, [nftAuctionAdd.getAddress], { initializer: 'initialize' });


};

module.exports.tags = ['NftAuctionProxy'];