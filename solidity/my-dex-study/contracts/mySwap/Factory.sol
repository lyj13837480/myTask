// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/IFactory.sol";
import "./Pool.sol";

contract Factory is IFactory {
    mapping(address => mapping(address => address[])) public pools;

    Parameters public override parameters;

    function sortToken(address tokenA, address tokenB) private pure returns (address token0,address token1){
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        } else {
            return (tokenB, tokenA);
        }
    } 
    
    // 获取池子地址
    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view override returns (address pool) {
        require(tokenA != tokenB, "Factory: identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Factory: zero address");
        // 排序地址小的在前
        (address token0, address token1) = sortToken(tokenA, tokenB);
        pool = pools[token0][token1][index];
    }
    // 创建池子
    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external override returns (address pool) {
        require(tokenA != tokenB, "Factory: identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Factory: zero address");
        // 排序地址小的在前
        address token0;
        address token1;
        ( token0, token1) = sortToken(tokenA, tokenB);

        address[] storage existingPools = pools[token0][token1];

        for (uint i = 0; i < existingPools.length; i++) {
            IPool existingPool = IPool(existingPools[i]);
            if (
                existingPool.tickLower() == tickLower &&
                existingPool.tickUpper() == tickUpper &&
                existingPool.fee() == fee
            ) {
                return existingPools[i];
            }
        }

        parameters = Parameters({
            factory: address(this),
            tokenA: token0,
            tokenB: token1,
            tickLower: tickLower,
            tickUpper: tickUpper,
            fee: fee
        });

         bytes32 salt = keccak256(
            abi.encode(token0, token1, tickLower, tickUpper, fee)
        );
        
        pool = address(new Pool{salt: salt}());
        
        pools[token0][token1].push(pool);
        delete parameters;

        emit PoolCreated( token0,
         token1,
         uint32(pools[token0][token1].length - 1),
         tickLower,
         tickUpper,
         fee,
         pool);
    }
}