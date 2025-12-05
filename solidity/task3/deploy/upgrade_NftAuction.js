const { deployments, ethers, upgrades } = require("hardhat")
const fs = require("fs")
const path = require("path")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    const NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");

    console.log("部署用户地址：", deployer);
    console.log("读取文件");
    const storePath = path.resolve(__dirname, "proxyNftAuction.json");
    const storeData = fs.readFileSync(storePath, "utf-8");

    const { proxyAddress, implAddress, abi } = JSON.parse(storeData);

    const nftAuctionProxy = await upgrades.upgradeProxy(proxyAddress, NftAuctionV2);

    await nftAuctionProxy.waitForDeployment();
    console.log("升级成功");

    const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("代理合约地址：", proxyAddress);
    console.log("实现合约地址V2：", implAddressV2);

    const storePathV2 = path.resolve(__dirname, "proxyNftAuctionV2.json");
    fs.writeFileSync(
        storePathV2,
        JSON.stringify({
            proxyAddress,
            implAddressV2,
            abi: NftAuctionV2.interface.format("json"),
        })
    );

    await save("NftAuctionV2", {
        abi: NftAuctionV2.interface.format("json"),
        address: proxyAddress,
        // args: [],
        // log: true,
    })
}

module.exports.tags = ["upgradeNftAuction"];