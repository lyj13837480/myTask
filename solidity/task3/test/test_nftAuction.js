const { expect } = require("chai")
const { ethers, deployments, upgrades } = require("hardhat")

describe("NftAuction", function () {
    it("Should deploy successfully", async function () {
        await main();
    });
});

async function main() {
    const [signer, buyer] = await ethers.getSigners()
    // await deployments.fixture(["NftAuction"]);

    // const nftAuctionProxy = await deployments.get("NftAuction");
    // const nftAuction = await ethers.getContractAt(
    //     "NftAuction",
    //     nftAuctionProxy.address
    // );

    // console.log("nftAuctionProxy:", nftAuctionProxy.address);

    //部署合约MyERC20
    const MyERC20 = await ethers.getContractFactory("MyERC20");
    const myERC20 = await MyERC20.deploy();
    await myERC20.waitForDeployment();
    const tokenAddress = await myERC20.getAddress();
    console.log("tokenAddress:", tokenAddress);
    //buyer获取代币
    let tx = await myERC20.connect(signer).transfer(buyer, ethers.parseEther("1000"));
    await tx.wait();
    console.log("buyer balance:", await myERC20.balanceOf(buyer));

    //部署合约MyNft
    const MyNft = await ethers.getContractFactory("MyNft");
    const myNft = await MyNft.deploy("MyNft");
    await myNft.waitForDeployment();
    const nftAddress = await myNft.getAddress();
    console.log("nftAddress:", nftAddress);

    //铸造5个NFT
    for (let i = 0; i < 5; i++) {
        let tx1 = await myNft.connect(signer).mint(signer, i);
        await tx1.wait();
    }
    console.log("signer balance:", await myNft.balanceOf(signer));

    //部署合约NftAuction
    const NftAuction = await ethers.getContractFactory("NftAuction");
    const nftAuctionProxy = await upgrades.deployProxy(NftAuction, [], { initializer: 'initialize' });
    await nftAuctionProxy.waitForDeployment();

    const nftAuctionProxyAddress = await nftAuctionProxy.getAddress();
    console.log("nftAuctionProxy:", nftAuctionProxyAddress);
    //授权NFT给nftAuctionProxy
    await myNft.connect(signer).setApprovalForAll(nftAuctionProxyAddress, true);

    //创建询价预言机 ETH 何USDC
    const aggreagatorV3 = await ethers.getContractFactory("AggreagatorV3")
    const priceFeedEthDeploy = await aggreagatorV3.deploy(ethers.parseEther("10000"))
    const priceFeedEth = await priceFeedEthDeploy.waitForDeployment()
    const priceFeedEthAddress = await priceFeedEth.getAddress()
    console.log("ethFeed: ", priceFeedEthAddress)
    const priceFeedUSDCDeploy = await aggreagatorV3.deploy(ethers.parseEther("1"))
    const priceFeedUSDC = await priceFeedUSDCDeploy.waitForDeployment()
    const priceFeedUSDCAddress = await priceFeedUSDC.getAddress()
    console.log("usdcFeed: ", priceFeedUSDCAddress)

    const token2Usd = [{
        token: ethers.ZeroAddress,
        priceFeed: priceFeedEthAddress
    }, {
        token: tokenAddress,
        priceFeed: priceFeedUSDCAddress
    }]
    //设置价格
    for (let i = 0; i < token2Usd.length; i++) {
        const { token, priceFeed } = token2Usd[i];
        await nftAuctionProxy.setPriceFeed(token, priceFeed);
    }

    //创建拍卖
    await nftAuctionProxy.connect(signer).createAuction(5, //持续时间
        ethers.parseEther("0.001"), //起始价格
        nftAddress, //NFT合约地址
        1 //NFT ID
    );
    const auction = await nftAuctionProxy.auctions(0);
    console.log("创建成功：：", auction);
    //拍卖 ETH参与
    tx = await nftAuctionProxy.connect(buyer).placeBid(0, 0, ethers.ZeroAddress, { value: ethers.parseEther("0.01") });
    await tx.wait();
    console.log("拍卖成功ETH");
    // USDC参与竞价
    tx = await myERC20.connect(buyer).approve(nftAuctionProxyAddress, ethers.parseEther("1000"))
    await tx.wait()
    console.log("授权成功token");
    tx = await nftAuctionProxy.connect(buyer).placeBid(0, ethers.parseEther("101"), tokenAddress);
    await tx.wait()

    // 4. 结束拍卖
    // 等待 10 s
    await new Promise((resolve) => setTimeout(resolve, 5 * 1000));
    const auction1 = await nftAuctionProxy.auctions(0);

    console.log("创建结束：：", auction1, buyer.address);
    await nftAuctionProxy.connect(signer).endAuction(0);

    // 验证结果
    const auctionResult = await nftAuctionProxy.auctions(0);
    console.log("结束拍卖后读取拍卖成功：：", auctionResult);
    expect(auctionResult.highestBidder).to.equal(buyer.address);
    expect(auctionResult.highestBid).to.equal(ethers.parseEther("101"));

    // 验证 NFT 所有权
    const owner = await myNft.ownerOf(1);
    console.log("owner::", owner);
    expect(owner).to.equal(buyer.address);
}

main()