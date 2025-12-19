// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";
import "./libs/TickMath.sol";
import "./libs/FullMath.sol";
import "./libs/FixedPoint128.sol";
import "./libs/SqrtPriceMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";
import "./libs/SwapMath.sol";

contract Pool is IPool {
    using SafeCast for uint256;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    // 工厂地址 
    address public immutable override factory;
    // 代币0
    address public immutable override token0;
    // 代币1
    address public immutable override token1;
    // 手续费
    uint24 public immutable override fee;
    // tick下限
    int24 public immutable override tickLower;
    //  tick上限
    int24 public immutable override tickUpper;

    /// 当前价格
    uint160 public override sqrtPriceX96;
    /// 当前tick
    int24 public override tick;
    /// 流动性
    uint128 public override liquidity;

    /// 代币0的累计手续费
    uint256 public override feeGrowthGlobal0X128;
    /// 代币1的累计手续费
    uint256 public override feeGrowthGlobal1X128;

    struct Position {
        // 该 Position 拥有的流动性
        uint128 liquidity;
        // 可提取的 token0 数量
        uint128 tokensOwed0;
        // 可提取的 token1 数量
        uint128 tokensOwed1;
        // 上次提取手续费时的 feeGrowthGlobal0X128
        uint256 feeGrowthInside0LastX128;
        // 上次提取手续费是的 feeGrowthGlobal1X128
        uint256 feeGrowthInside1LastX128;
    }
    // LP 的 Position 信息
    mapping(address owner => Position position) public  positions;

    constructor(){
        // 获取工厂参数完成初始化
        (
            factory,
            token0,
            token1,
            tickLower,
            tickUpper,
            fee
        ) = IFactory(msg.sender).parameters();
    }
    // 初始化池子价格
    function initialize(uint160 sqrtPriceX96_) external override {
        require(sqrtPriceX96_ > 0, "sqrtPriceX96_ must be greater than 0");
        require(msg.sender == factory, "Pool: only factory can initialize");
        // 初始化逻辑
        tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96_);
        require(
            tick >= tickLower && tick < tickUpper,
            "sqrtPriceX96_ out of range for tick"
        );
        sqrtPriceX96 = sqrtPriceX96_;
    }

    function getPosition(address owner)external view override
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ){
            _liquidity = positions[owner].liquidity;
            feeGrowthInside0LastX128 = positions[owner].feeGrowthInside0LastX128;
            feeGrowthInside1LastX128 = positions[owner].feeGrowthInside1LastX128;
            tokensOwed0 = positions[owner].tokensOwed0;
            tokensOwed1 = positions[owner].tokensOwed1;
        }

    struct ModifyPositionParams {
        // Position 拥有者
        address owner;
        // 池子流动性
        int128 liquidityDelta;
    }
    // 修改仓位，增加或减少流动性
    function _modifyPosition(
        ModifyPositionParams memory params
    ) private returns (int256 amount0, int256 amount1) { 
        Position storage position = positions[params.owner];
        
        if(position.liquidity > 0){
            // 计算可提取的token0和token1手续费 安全计算 uint128((fee * position.liquidity) >> 128)
            uint128 tokensOwed0 = uint128(
            FullMath.mulDiv(
                feeGrowthGlobal0X128 - position.feeGrowthInside0LastX128,
                position.liquidity,
                FixedPoint128.Q128
            ));
            uint128 tokensOwed1 = uint128(
            FullMath.mulDiv(
                feeGrowthGlobal1X128 - position.feeGrowthInside1LastX128,
                position.liquidity,
                FixedPoint128.Q128
            ));
            position.tokensOwed0 += tokensOwed0;
            position.tokensOwed1 += tokensOwed1;
        }

        position.feeGrowthInside0LastX128 = feeGrowthGlobal0X128;
        position.feeGrowthInside1LastX128 = feeGrowthGlobal1X128;
        // 增加流动性
        if (params.liquidityDelta > 0) {
            position.liquidity += uint128(params.liquidityDelta);
            liquidity += uint128(params.liquidityDelta);
        } else {
            position.liquidity -= uint128(-params.liquidityDelta);
            liquidity -= uint128(-params.liquidityDelta);
        }   
        // 计算需要的token0和token1数量
        amount0 = SqrtPriceMath.getAmount0Delta(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickUpper),
            params.liquidityDelta
        );
        amount1 = SqrtPriceMath.getAmount1Delta(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            params.liquidityDelta
        );
    } 
    // 获取池代币0余额
    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
    
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }   

    // 铸造流动性 recipient接收流动性份额的地址 amount铸造的流动性数量 data回调数据
    function mint(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) external override returns (uint256 amount0, uint256 amount1){
        require(amount > 0, "amount must be greater than 0");
        // 修改仓位，增加流动性
        (int256 amt0,int256 amt1) = _modifyPosition(ModifyPositionParams({
            owner: recipient,
            liquidityDelta: int128(amount)
        }));

        amount0 = uint256(amt0);
        amount1 = uint256(amt1);

        uint256 balance0Before;
        uint256 balance1Before;
        
        if (amount0 > 0) { 
            balance0Before = balance0();
        }
        if (amount1 > 0) {
            balance1Before = balance1();
        }

        // 回调 mintCallback
        IMintCallback(msg.sender).mintCallback(amount0, amount1, data);
        
        if (amount0 > 0)
            require(balance0Before.add(amount0) <= balance0(), "M0");
        if (amount1 > 0)
            require(balance1Before.add(amount1) <= balance1(), "M1");

        emit Mint(msg.sender, recipient, amount, amount0, amount1);
    
    }

    
    // 收集用户在当前池子中的流动性的token0和token1手续费
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override returns (uint128 amount0, uint128 amount1) {
        Position storage position = positions[msg.sender];
        // 获取可提取的token0和token1手续费 判断用户提取数量是否超过可提取数量 超过按照可提取数量处理
        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;
        // 转账用户手续费
        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }
        emit Collect(msg.sender, recipient, amount0, amount1);
    }

    
    // 销毁流动性，返回对应的token0和token1数量
    function burn(
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        (int256 amt0,int256 amt1) = _modifyPosition(ModifyPositionParams({
            owner: msg.sender,
            liquidityDelta: -int128(amount)
        }));
        amount0 = uint256(-amt0);
        amount1 = uint256(-amt1);
        Position storage position = positions[msg.sender];
        if(amount0 > 0){
            position.tokensOwed0 += uint128(amount0);
        }
        if(amount1 > 0){
            position.tokensOwed1 += uint128(amount1);
        }

        emit Burn(msg.sender, amount, amount0, amount1);
    }

    struct SwapState {
        // 输入/输出资产中剩余待交换的金额
        int256 amountSpecifiedRemaining;
        // 输出/输入资产已换出/换入的金额
        int256 amountCalculated;
        // 当前价格
        uint160 sqrtPriceX96;
        // 输入token的全局费用
        uint256 feeGrowthGlobalX128;
        // 该交易中用户转入的 token 的数量
        uint256 amountIn;
        // 该交易中用户转出的 token 的数量
        uint256 amountOut;
        // 该交易中的手续费，如果 zeroForOne 是 ture，则是用户转入 token0，单位是 token0 的数量，反之是 token1 的数量
        uint256 feeAmount;
    }
    
    // 交换token0和token1
    // `amountSpecified` 大于 0 代表我们指定了要支付的 token0 的数量，`amountSpecified` 小于 0 则代表我们指定了要获取的 token1 的数量。
    //`zeroForOne` 为 `true` 代表了是 token0 换 token1，反之则相反。如果是 token0 换 token1，那么交易会导致池子的 token0 变多，价格下跌，
    //我们需要验证 `sqrtPriceLimitX96` 必须小于当前的价格，也就是指 `sqrtPriceLimitX96` 是交易的一个价格下限。
    //另外价格也需要大于可用的最小价格和小于可用的最大价格。
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        // zeroForOne: 如果从 token0 交换 token1 则为 true，从 token1 交换 token0 则为 false
        // 判断当前价格是否满足交易的条件
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < sqrtPriceX96 &&
                    sqrtPriceLimitX96 > TickMath.MIN_SQRT_PRICE
                : sqrtPriceLimitX96 > sqrtPriceX96 &&
                    sqrtPriceLimitX96 < TickMath.MAX_SQRT_PRICE,
            "SPL"
        );

        // amountSpecified 大于 0 代表用户指定了 token0 的数量，小于 0 代表用户指定了 token1 的数量
        bool exactInput = amountSpecified > 0;

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: sqrtPriceX96,
            feeGrowthGlobalX128: zeroForOne ? feeGrowthGlobal0X128 : feeGrowthGlobal1X128,
            amountIn: 0,
            amountOut: 0,
            feeAmount: 0
        }); 

        uint160 sqrtPriceX96Lower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtPriceX96Upper = TickMath.getSqrtPriceAtTick(tickUpper);
        // 开始交换逻辑
        // 计算用户交易价格的限制，如果是 zeroForOne 是 true，说明用户会换入 token0，会压低 token0 的价格（也就是池子的价格）
        // 所以要限制最低价格不能超过 sqrtPriceX96Lower
        uint160 sqrtPriceX96PoolLimit = zeroForOne ? sqrtPriceX96Lower : sqrtPriceX96Upper;

        // 计算交易的具体数值
        (
            state.sqrtPriceX96,
            state.amountIn,
            state.amountOut,
            state.feeAmount
        ) = SwapMath.computeSwapStep(
            sqrtPriceX96,
            (
                zeroForOne
                    ? sqrtPriceX96PoolLimit < sqrtPriceLimitX96
                    : sqrtPriceX96PoolLimit > sqrtPriceLimitX96
            )
                ? sqrtPriceLimitX96
                : sqrtPriceX96PoolLimit,
            liquidity,
            amountSpecified,
            fee
        );

        // 更新池子状态
        sqrtPriceX96 = state.sqrtPriceX96;
        tick = TickMath.getTickAtSqrtPrice(state.sqrtPriceX96);

        // 计算每个流动性节点的手续费
        state.feeGrowthGlobalX128 += FullMath.mulDiv(
            state.feeAmount,
            FixedPoint128.Q128,
            liquidity
        );
        // 更新费用
        if(zeroForOne){
        feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;
        } else {
            feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;
        }

        // 计算交易结果
        // 计算交易后用户手里的 token0 和 token1 的数量
        if (exactInput) {
            state.amountSpecifiedRemaining -= (state.amountIn + state.feeAmount)
                .toInt256();
            state.amountCalculated = state.amountCalculated.sub(
                state.amountOut.toInt256()
            );
        } else {
            state.amountSpecifiedRemaining += state.amountOut.toInt256();
            state.amountCalculated = state.amountCalculated.add(
                (state.amountIn + state.feeAmount).toInt256()
            );
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (
                amountSpecified - state.amountSpecifiedRemaining,
                state.amountCalculated
            )
            : (
                state.amountCalculated,
                amountSpecified - state.amountSpecifiedRemaining
        );

        // 转账
        if(zeroForOne){
            // callback 中需要给 Pool 转入 token0
            uint256 balance0Before = balance0();
            ISwapCallback(msg.sender).swapCallback(amount0, amount1, data);
            require(balance0Before.add(uint256(amount0)) <= balance0(), "IIA");

            // 转 Token1 给用户
            if (amount1 < 0)
                TransferHelper.safeTransfer(
                    token1,
                    recipient,
                    uint256(-amount1)
                );
        }else{
            // callback 中需要给 Pool 转入 token1
            uint256 balance1Before = balance1();
            ISwapCallback(msg.sender).swapCallback(amount0, amount1, data);
            require(balance1Before.add(uint256(amount1)) <= balance1(), "IIA");

            // 转 Token0 给用户
            if (amount0 < 0)
                TransferHelper.safeTransfer(
                    token0,
                    recipient,
                    uint256(-amount0)
            );
        }

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            sqrtPriceX96,
            liquidity,
            tick
        );
    }

    
}