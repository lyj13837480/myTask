// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/IPoolManager.sol";
import "./Factory.sol";

contract PoolManage is Factory,IPoolManager {
    Pair[] public pairs;
   // 获取所有币对
    function getPairs() external view override returns (Pair[] memory) {
        return pairs;
    }

    // 获取所有池子信息
    function getAllPools() external view override returns (PoolInfo[] memory allPools){
        uint256 totalPools = 0;
        // 计算总池子数量
        for (uint i = 0; i < pairs.length; i++) {
            totalPools += pools[pairs[i].token0][pairs[i].token1].length;
        }
        if (totalPools == 0) {
            return new PoolInfo[](0);
        }
        allPools = new PoolInfo[](totalPools);
        uint256 index;
        for(uint32 i = 0; i < pairs.length; i++) {
            address[] memory poolAddress = pools[pairs[i].token0][pairs[i].token1];
            for(uint32 j = 0; j < poolAddress.length; j++){
                IPool pool = IPool(poolAddress[j]);
                allPools[index] = PoolInfo({
                    pool: poolAddress[j],
                    token0: pool.token0(),
                    token1: pool.token1(),
                    index: j,
                    fee: pool.fee(),
                    feeProtocol: 0,
                    tickLower: pool.tickLower(),
                    tickUpper: pool.tickUpper(),
                    tick: pool.tick(),
                    sqrtPriceX96: pool.sqrtPriceX96(),
                    liquidity: pool.liquidity()
                });
                index++;
            }
        }
        return allPools;
    }

    // 创建池子并初始化
    function createAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable override returns (address pool) {
        require(params.token0 < params.token1, "PoolManager: token0 must be less than token1");
        // 创建池子
        pool = this.createPool(params.token0, params.token1,params.tickLower,params.tickUpper, params.fee);
        
        IPool iPool = IPool(pool);
        uint256 length = pools[params.token0][params.token1].length;
        // 初始化池子
        if(iPool.sqrtPriceX96() == 0){
            // 初始化池子
            iPool.initialize(params.sqrtPriceX96);
            if (length == 1) {
                pairs.push(Pair({token0: params.token0, token1: params.token1}));
            }
        }
    }
}