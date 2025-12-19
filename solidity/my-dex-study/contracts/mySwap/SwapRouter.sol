// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/ISwapRouter.sol";
import "./interfaces/IPoolManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapRouter is ISwapRouter {
    // 池子管理器
    IPoolManager public poolManager;

    constructor(address _poolManager) {
        // 初始化池子管理器
        poolManager = IPoolManager(_poolManager);
    }

    function parseRevertReason(
        bytes memory reason
    ) private pure returns (int256, int256) {
        if (reason.length != 64) {
            if (reason.length < 68) revert("Unexpected error");
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (int256, int256));
    }
    // 进行交易，且对异常进行捕获处理
    function swapInPool(
        IPool pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        try
            pool.swap(
                recipient,
                zeroForOne,
                amountSpecified,
                sqrtPriceLimitX96,
                data
            )
        returns (int256 _amount0, int256 _amount1) {
            return (_amount0, _amount1);
        } catch (bytes memory reason) {
            return parseRevertReason(reason);
        }
    }

    // 按照tokenInput固定进行交易
    function exactInput(
        ExactInputParams calldata params
    ) external payable override returns (uint256 amountOut){
        
        uint256 amountIn = params.amountIn; // 输入数量
        bool zeroForOne = params.tokenIn < params.tokenOut ? true : false; // 交易方向
        // 遍历池子路径进行交易
        for(uint256 i = 0; i < params.indexPath.length; i++){
            // 获取池子
            address pool = poolManager.getPool(params.tokenIn, params.tokenOut, params.indexPath[i]);
            require(pool != address(0), "Pool not found");
            // 组装数据 swapCallback方法回调参数
            bytes memory data = abi.encode(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i],
                msg.sender
            );
            // 交易
            (int256 amount0, int256 amount1) =
            this.swapInPool(
                IPool(pool),
                params.recipient,
                zeroForOne,
                int256(amountIn),
                params.sqrtPriceLimitX96,
                data
            );

            // 更新 amountIn 和 amountOut
            amountIn -= uint256(zeroForOne ? amount0 : amount1);
            amountOut += uint256(zeroForOne ? -amount1 : -amount0);

            if(amountIn == 0){
                break;
            }
        }
        require(amountOut >= params.amountOutMinimum, "Not enough input");
        return amountOut;

    }
    // 按照tokenOutput固定进行交易
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable override returns (uint256 amountIn){
        uint256 amountOut = params.amountOut; // 输出数量
        bool zeroForOne = params.tokenIn < params.tokenOut ? true : false; // 交易方向
        // 遍历池子路径进行交易
        for(uint256 i = 0; i < params.indexPath.length; i++){
            // 获取池子
            address pool = poolManager.getPool(params.tokenIn, params.tokenOut, params.indexPath[i]);
            require(pool != address(0), "Pool not found");
            // 组装数据 swapCallback方法回调参数
            bytes memory data = abi.encode(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i],
                msg.sender
            );
            // 交易
            (int256 amount0, int256 amount1) =
            this.swapInPool(
                IPool(pool),
                params.recipient,
                zeroForOne,
                -int256(amountOut),
                params.sqrtPriceLimitX96,
                data
            );

            // 更新 amountIn 和 amountOut
            amountIn += uint256(zeroForOne ? amount0 : amount1);
            amountOut -= uint256(zeroForOne ? -amount1 : -amount0);

            if(amountOut == 0){
                break;
            }
        }
        require(amountIn <= params.amountInMaximum, "Not enough output");
        return amountIn;
    }
    
    // 预估输出数量
    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external override returns (uint256 amountOut){
        return
            this.exactInput(
                ExactInputParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    indexPath: params.indexPath,
                    recipient: address(0),
                    deadline: block.timestamp + 1 hours,
                    amountIn: params.amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );
    }
    
    // 预估输入数量
    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external override returns (uint256 amountIn){
         return
            this.exactOutput(
                ExactOutputParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    indexPath: params.indexPath,
                    recipient: address(0),
                    deadline: block.timestamp + 1 hours,
                    amountOut: params.amountOut,
                    amountInMaximum: type(uint256).max,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );
    }

    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        (address tokenIn, address tokenOut, uint32 index, address payer) = abi
            .decode(data, (address, address, uint32, address));
        address _pool = poolManager.getPool(tokenIn, tokenOut, index);

        // 检查 callback 的合约地址是否是 Pool
        require(_pool == msg.sender, "Invalid callback caller");

        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
        // payer 是 address(0)，这是一个用于预估 token 的请求（quoteExactInput or quoteExactOutput）
        // 参考代码 https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/Quoter.sol#L38
        if (payer == address(0)) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amount0Delta)
                mstore(add(ptr, 0x20), amount1Delta)
                revert(ptr, 64)
            }
        }

        // 正常交易，转账给交易池
        if (amountToPay > 0) {
            IERC20(tokenIn).transferFrom(payer, _pool, amountToPay);
        }
    }
}