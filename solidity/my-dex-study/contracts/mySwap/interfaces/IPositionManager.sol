// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPool.sol";

interface IPositionManager is IMintCallback,IERC721 {
    // LP 仓位信息结构体
    struct PositionInfo {
        uint256 id; // ID
        address owner; // 拥有者
        address token0; // 币种0
        address token1; // 币种1
        uint32 index; // 仓位索引
        uint24 fee; // 手续费
        uint128 liquidity; // 流动性
        int24 tickLower; // 仓位下边界
        int24 tickUpper; // 仓位上边界
        uint128 tokensOwed0; // 待提取的token0
        uint128 tokensOwed1; // 待提取的token1  
        // feeGrowthInside0LastX128 和 feeGrowthInside1LastX128 用于计算手续费
        uint256 feeGrowthInside0LastX128; // 记录上次计算手续费时的 feeGrowthInside0X128
        uint256 feeGrowthInside1LastX128; // 记录上次计算手续费时的 feeGrowthInside1X128
    }
    // 获取所有仓位信息
    function getAllPositions() external view returns (PositionInfo[] memory);
    // 铸造仓位信息
    struct MintParams {
        address token0; // 币种0
        address token1; // 币种1
        uint32 index; // 索引
        uint256 amount0Desired; // 期望的币种0数量
        uint256 amount1Desired; // 期望的币种1数量
        address recipient; // 接收仓位的地址
        uint256 deadline; // 截止时间
    }
    // 铸造仓位
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 positionId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
    // 移仓
    function burn(uint256 positionId) external returns (uint256 amount0, uint256 amount1);
    // 提取代币
    function collect(
        uint256 positionId,
        address recipient
    ) external returns (uint256 amount0, uint256 amount1);

    // // 仓位回调
    // function mintCallback(uint256 amount0,uint256 amount1,bytes calldata data)  external;

}