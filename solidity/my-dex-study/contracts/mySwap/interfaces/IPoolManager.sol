// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "./IFactory.sol";

interface IPoolManager is IFactory {
    // 池子信息结构体
    struct PoolInfo {
        address pool; // 池子地址
        address token0; // token0
        address token1; // token1
        uint32 index; // 池子索引
        uint24 fee; // 手续费
        uint8 feeProtocol; // 池子协议费
        int24 tickLower; // 池子下界
        int24 tickUpper; // 池子上界
        int24 tick; // 池子tick
        uint160 sqrtPriceX96; // 池子sqrtPriceX96
        uint128 liquidity; // 池子流动性
    }
    // 币对
    struct Pair {
        address token0;
        address token1;
    }
    // 获取所有币对
    function getPairs() external view returns (Pair[] memory);
    // 获取所有池子信息
    function getAllPools() external view returns (PoolInfo[] memory);

    struct CreateAndInitializeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
    }
    // 创建池子并初始化
    function createAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable returns (address pool);
}