// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./IPool.sol";

interface ISwapRouter is ISwapCallback {
    
    event Swap(
        address indexed sender,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountInRemaining,
        uint256 amountOut
    );
    // input参数
    struct ExactInputParams {
        address tokenIn; // tokenIn
        address tokenOut; // tokenOut
        uint32[] indexPath; // 池子索引路径
        address recipient; // 接收地址
        uint256 deadline; // 截止时间
        uint256 amountIn; // 输入数量
        uint256 amountOutMinimum; // 最小输出数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
    // output参数
    struct ExactOutputParams {
        address tokenIn; // tokenIn
        address tokenOut; // tokenOut
        uint32[] indexPath; // 池子索引路径
        address recipient; // 接收地址
        uint256 deadline; // 截止时间
        uint256 amountOut; // 输出数量
        uint256 amountInMaximum; // 最大输入数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
    // quote input 参数
    struct QuoteExactInputParams {
        address tokenIn; // tokenIn
        address tokenOut; // tokenOut
        uint32[] indexPath; // 池子索引路径
        uint256 amountIn; // 输入数量
        uint160 sqrtPriceLimitX96;
    }
    // 预估输出数量
    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external returns (uint256 amountOut);
    // quote output 参数
    struct QuoteExactOutputParams {
        address tokenIn; // tokenIn
        address tokenOut; // tokenOut
        uint32[] indexPath; // 池子索引路径
        uint256 amountOut; // 输出数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }
    // 预估输入数量
    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external returns (uint256 amountIn);
    
}