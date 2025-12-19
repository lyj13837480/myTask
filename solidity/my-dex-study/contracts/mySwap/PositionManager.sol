// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/IPositionManager.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IPoolManager.sol";
import "./interfaces/IPool.sol";
import "./libs/LiquidityAmounts.sol";
import "./libs/TickMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PositionManager is ERC721, IPositionManager {
    
    IPoolManager public poolManager;
    
    uint176 private _nextId = 1; // 下一个仓位ID，初始值为1
    mapping(uint256 => PositionInfo) private _positions;
    
    constructor(address poolManagerAddress) ERC721("PositionManager", "PM") {
        // 初始化池管理器
        poolManager = IPoolManager(poolManagerAddress);
    }
    
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction expired");
        _;
    }

    modifier onlyOwner(uint256 positionId) {
        require(ownerOf(positionId) == msg.sender, "PositionManager: caller is not the owner");
        _;
    }

    // 获取所有仓位信息
    function getAllPositions() external view override returns (PositionInfo[] memory positionInfos) {
        positionInfos = new PositionInfo[](_nextId - 1);
        for(uint256 i = 1; i < _nextId; i++) {
            positionInfos[i - 1] = _positions[i];
        }
        return positionInfos;
    }
    
    // 铸造仓位
    function mint(MintParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (
            uint256 positionId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ){
            // mint 一个 NFT 作为 position 发给 LP
            // NFT 的 tokenId 就是 positionId
            // 通过 MintParams 里面的 token0 和 token1 以及 index 获取对应的 Pool
            // 调用 poolManager 的 getPool 方法获取 Pool 地址
            IPool pool = IPool(
                poolManager.getPool(params.token0, params.token1, params.index)
            );
            require(address(pool) != address(0), "PositionManager: pool does not exist");
            //计算流动性
            uint160 sqrtPriceX96 = pool.sqrtPriceX96();
            uint160 sqrtPriceX96Lower = TickMath.getSqrtPriceAtTick(pool.tickLower());
            uint160 sqrtPriceX96Upper = TickMath.getSqrtPriceAtTick(pool.tickUpper());

            liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, 
            sqrtPriceX96Lower, sqrtPriceX96Upper, params.amount0Desired, params.amount1Desired);
            bytes memory data = abi.encode(
            params.token0,
            params.token1,
            params.index,
            msg.sender
            );
            // 调用 Pool 的 mint 方法铸造流动性
            ( amount0,  amount1) = pool.mint(params.recipient,liquidity,data);
            positionId = _nextId++;
            _mint(params.recipient, positionId); // 铸造 NFT 给 LP

            (
            ,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            ,

        ) = pool.getPosition(address(this));
            // 存储仓位信息
            _positions[positionId] = PositionInfo({
                id: positionId,
                owner: params.recipient,
                token0: params.token0,
                token1: params.token1,
                index: params.index,
                fee: pool.fee(),
                liquidity: liquidity,
                tickLower: pool.tickLower(),
                tickUpper: pool.tickUpper(),
                tokensOwed0: 0,
                tokensOwed1: 0,
                feeGrowthInside0LastX128: feeGrowthInside0LastX128,
                feeGrowthInside1LastX128: feeGrowthInside1LastX128
            });
            return (positionId, liquidity, amount0, amount1);
        }
    // 移仓
    function burn(uint256 positionId) external override onlyOwner(positionId) returns (uint256 amount0, uint256 amount1){
        IPool pool = IPool(
            poolManager.getPool(
                _positions[positionId].token0,
                _positions[positionId].token1,
                _positions[positionId].index
            )
        );
        require(address(pool) != address(0), "PositionManager: pool does not exist");
        // 调用 Pool 的 burn 方法销毁流动性
        (amount0,amount1) = pool.burn(_positions[positionId].liquidity);
        // 计算手续费
        (
            ,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            ,

        ) = pool.getPosition(address(this));

        uint128 feesOwed0 = uint128(amount0) + uint128(
            FullMath.mulDiv(
                _positions[positionId].liquidity,
                feeGrowthInside0LastX128 - _positions[positionId].feeGrowthInside0LastX128,
                2**128
            )
        );
        uint128 feesOwed1 = uint128(amount1) + uint128(
            FullMath.mulDiv(
                _positions[positionId].liquidity,
                feeGrowthInside1LastX128 - _positions[positionId].feeGrowthInside1LastX128,
                2**128
            )
        );
        //更新仓位信息
        _positions[positionId].tokensOwed0 += feesOwed0;
        _positions[positionId].tokensOwed1 += feesOwed1;
        _positions[positionId].feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        _positions[positionId].feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        _positions[positionId].liquidity = 0;
    }
    // 提取代币
    function collect(
        uint256 positionId,
        address recipient
    ) external override onlyOwner(positionId) returns (uint256 amount0, uint256 amount1){
        IPool pool = IPool(
            poolManager.getPool(
                _positions[positionId].token0,
                _positions[positionId].token1,
                _positions[positionId].index
            )
        );
        require(address(pool) != address(0), "PositionManager: pool does not exist");
        // 调用 Pool 的 collect 方法收集手续费
        (uint128 collected0, uint128 collected1) = pool.collect(
            address(this),
            _positions[positionId].tokensOwed0,
            _positions[positionId].tokensOwed1
        );
        
        // 更新仓位信息
        _positions[positionId].tokensOwed0 = 0;
        _positions[positionId].tokensOwed1 = 0;
        // 销毁 NFT
        _burn(positionId);
        return (collected0, collected1);
    }


    // 移仓回调
    function mintCallback(uint256 amount0,uint256 amount1,bytes calldata data)  external override{
        (
            address token0,
            address token1,
            uint24 index,
            address owner
        ) = abi.decode(data, (address, address, uint24, address));
        require(msg.sender == poolManager.getPool(token0, token1, index), "PositionManager: invalid pool");
        // 将代币转给 Pool
        if (amount0 > 0) {
            IERC20(token0).transferFrom(owner, msg.sender, amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).transferFrom(owner, msg.sender, amount1);
        }
    }
}