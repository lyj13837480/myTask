// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftAuction {
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

    // 状态变量
    mapping(uint256 => Auction) public auctions;
    // 下一个拍卖ID
    uint256 public nextAuctionId;
    // 管理员地址
    address public admin;

    //初始化管理员地址
    function initialize() public initializer {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function createAuction(
        uint256 _duration, //持续时间
        uint256 _startPrice, //起始价格
        address _nftAddress, //NFT合约地址
        uint256 _tokenId //NFT ID
    ) public onlyAdmin {
        require(_duration > 0, "Duration must be greater than 0");
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_nftAddress != address(0), "NFT address cannot be zero");
        //require(_tokenId > 0, "Token ID must be greater than 0");
        //要求是NFT的owner或者approved
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender ||
                IERC721(_nftAddress).getApproved(_tokenId) == msg.sender ||
                IERC721(_nftAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "you are not the owner of this NFT"
        );

        // 创建一个拍卖
        Auction memory auction = Auction({
            seller: msg.sender,
            duration: _duration,
            startPrice: _startPrice,
            startTime: block.timestamp,
            ended: false,
            highestBidder: address(0), //默认为空
            highestBid: 0,
            nftContract: _nftAddress,
            tokenId: _tokenId
        });

        auctions[nextAuctionId] = auction;
        nextAuctionId++;
    }
}
