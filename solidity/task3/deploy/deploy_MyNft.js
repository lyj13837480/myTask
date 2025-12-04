const { deployments, upgrades, ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy('MyNft', {
        from: deployer,
        args: ['MyNft'],
        log: true,
    });
};
module.exports.tags = ['MyNft'];