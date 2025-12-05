// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NftAuction is Initializable, UUPSUpgradeable {
    // 结构体
    struct Auction {
        // 卖家
        address seller;
        // 拍卖持续时间
        uint256 duration;
        // 起始价格
        uint256 startPrice;
        // 开始时间
        uint256 startTime;
        // 是否结束
        bool ended;
        // 最高出价者
        address highestBidder;
        // 最高价格
        uint256 highestBid;
        // NFT合约地址
        address nftContract;
        // NFT ID
        uint256 tokenId;
        // 参与竞价的资产类型 0x 地址表示eth，其他地址表示erc20
        // 0x0000000000000000000000000000000000000000 表示eth
        address tokenAddress;
    }
    address public implementation; // 逻辑合约地址
    // 状态变量
    mapping(uint256 => Auction) public auctions;
    // 下一个拍卖ID
    uint256 public nextAuctionId;
    // 管理员地址
    address public admin;
    //价格预言机数据
    mapping(address => AggregatorV3Interface) public priceFeeds;

    //发送创建拍卖的event，方便监听
    event CreateAuct(uint256 auctionId, uint256 duration, uint256 startTime);

    function initialize() public initializer {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    //通过价格预言机设置汇率
    function setPriceFeed(address tokenAddress, address _priceFeed) public {
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeed);
    }

    //获取汇率
    // ETH -> USD => 1766 7512 1800 => 1766.75121800
    // USDC -> USD => 9999 4000 => 0.99994000
    function getChainlinkDataFeedLatestAnswer(
        address tokenAddress
    ) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return answer;
    }

    function createAuction(
        uint256 _duration, //持续时间
        uint256 _startPrice, //起始价格
        address _nftAddress, //NFT合约地址
        uint256 _tokenId //NFT ID
    ) public {
        require(_duration > 0, "Duration must be greater than 0");
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_nftAddress != address(0), "NFT address cannot be zero");
        //require(_tokenId > 0, "Token ID must be greater than 0");
        //要求是NFT的owner或者approved
        // require(
        //     IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender ||
        //         IERC721(_nftAddress).getApproved(_tokenId) == msg.sender ||
        //         IERC721(_nftAddress).isApprovedForAll(
        //             msg.sender,
        //             address(this)
        //         ),
        //     "you are not the owner of this NFT"
        // );

        //nft转入合约
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        // 创建一个拍卖
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: _duration,
            startPrice: _startPrice,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            startTime: block.timestamp,
            nftContract: _nftAddress,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });

        emit CreateAuct(nextAuctionId, _duration, block.timestamp);
        nextAuctionId++;
    }

    //参与拍卖
    function placeBid(
        uint256 _auctionID, // 拍卖ID
        uint256 amount, // 竞拍金额
        address _tokenAddress // 竞拍资产类型
    ) external payable {
        Auction storage auction = auctions[_auctionID];
        require(auction.seller != address(0), "bid auction not exist");
        console.log(
            "placeBid",
            auction.duration,
            auction.startTime,
            block.timestamp
        );
        // 判断当前拍卖是否结束
        require(
            !auction.ended &&
                auction.startTime + auction.duration > block.timestamp,
            "Auction has ended"
        );

        uint payValue;

        if (_tokenAddress != address(0)) {
            require(amount > 0, "Bid amount must be greater than 0");
            // 处理 ERC20
            // 检查是否是 ERC20 资产
            payValue =
                amount *
                uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            // 处理 ETH
            amount = msg.value;
            payValue =
                amount *
                uint(getChainlinkDataFeedLatestAnswer(address(0)));
        }

        //底价
        uint startPriceValue = auction.startPrice *
            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));
        //最高价
        uint highestBidValue = auction.highestBid *
            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

        require(
            payValue >= startPriceValue && payValue > highestBidValue,
            "Bid must be higher than the current highest bid"
        );

        // 转移 ERC20 到合约
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        // 退还前最高价
        if (auction.highestBid > 0) {
            if (auction.tokenAddress == address(0)) {
                // 退还之前的ETH
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                // 退回之前的ERC20
                IERC20(auction.tokenAddress).transfer(
                    auction.highestBidder,
                    auction.highestBid
                );
            }
        }
        console.log("amount:", amount);

        auction.highestBid = amount;
        auction.highestBidder = msg.sender;
        auction.tokenAddress = _tokenAddress;
    }

    // 结束拍卖
    function endAuction(uint256 _auctionID) external {
        Auction storage auction = auctions[_auctionID];

        console.log(
            "endAuction",
            auction.startTime,
            auction.duration,
            block.timestamp
        );
        // 判断当前拍卖是否结束
        require(
            !auction.ended &&
                (auction.startTime + auction.duration) <= block.timestamp,
            "Auction has not ended"
        );
        // 转移NFT到最高出价者
        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId
        );
        // 转移剩余的资金到卖家
        // payable(address(this)).transfer(address(this).balance);
        // 交易所应该有指定结算能力？
        if (auction.tokenAddress == address(0)) {
            // 结算ETH
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            // 结算ERC20
            IERC20(auction.tokenAddress).transfer(
                auction.seller,
                auction.highestBid
            );
        }
        auction.ended = true;
    }

    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }
}
