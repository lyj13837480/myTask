// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IFactory {
    // 参数结构体
    struct Parameters {
        address factory;// 工厂地址
        address tokenA;// tokenA
        address tokenB;// tokenB
        int24 tickLower;// 下限tick
        int24 tickUpper;// 上限tick
        uint24 fee;// 手续费
    }

    // 获取参数结构体
    function parameters()
        external
        view
        returns (
            address factory,
            address tokenA,
            address tokenB,
            int24 tickLower,
            int24 tickUpper,
            uint24 fee
        );
            
    event PoolCreated(
        address token0,
        address token1,
        uint32 index,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee,
        address pool
    );
    // 获取池子地址
    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view returns (address pool) ;
    // 创建池子
    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external returns (address pool) ;
}