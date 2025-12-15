// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MyStake is Initializable,UUPSUpgradeable,PausableUpgradeable,AccessControlUpgradeable {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256("admin_role");
    bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role");

    uint256 public constant ETH_PID = 0;

    struct Pool {
        address stTokenAddress; //质押代币的地址。
        uint256 poolWeight; //质押池的权重，影响奖励分配。
        uint256 lastRewardBlock; //最后一次计算奖励的区块号。
        uint256 accMetaNodePerST; //每个质押代币累积的 MetaNode 数量。
        uint256 stTokenAmount; //池中的总质押代币量。
        uint256 minDepositAmount; //最小质押金额。
        uint256 unstakeLockedBlocks; //解除质押的锁定区块数。
    }

    struct UnStakeRequest {
        // Request withdraw amount
        uint256 amount; // 用户取消质押的代币数量，要取出多少个 token
        // The blocks when the request withdraw amount can be released
        uint256 unlockBlocks; // 解质押的区块高度
    }

    struct User {
        // 记录用户相对每个资金池 的质押记录
        // Staking token amount that user provided
        // 用户在当前资金池，质押的代币数量
        uint256 stAmount;
        // Finished distributed MetaNodes to user 最终 MetaNode 得到的数量
        // 用户在当前资金池，已经领取的 MetaNode 数量
        uint256 finishedMetaNode;
        // Pending to claim MetaNodes 当前可取数量
        // 用户在当前资金池，当前可领取的 MetaNode 数量
        uint256 pendingMetaNode;
        // Withdraw request list
        // 用户在当前资金池，取消质押的记录
        UnStakeRequest[] requests;
    }

    uint256 public startBlock; // 开始区块
    uint256 public endBlock; // 结束区块
    uint256 public tokensPerBlock; // 每块奖励的 token 数量
    bool public withdrawEnabled; // 提现是否开启
    bool public claimEnabled; // 领取是否开启
    IERC20 public token; // 奖励代币合约地址
    Pool[] public pools; // 质押池数组
    mapping(uint256 => mapping(address => User)) public users; // poolId => user address
    uint256 public totalWeight; // 池总质押权重
    event WithdrawStopped();
    event WithdrawStarted();
    event ClaimStarted();
    event ClaimStopped();
    event StartBlockSet(uint256 startBlock);
    event EndBlockSet(uint256 endBlock);
    event TokensPerBlockSet(uint256 tokensPerBlock);
    event PoolAdded(
        uint256 indexed pid,
        address stTokenAddress,
        uint256 poolWeight,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks
    );
    event PoolUpdated(
        uint256 indexed pid,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks
    );
    event PoolWeightSet(uint256 _pid,uint256 _poolWeight,bool _withUpdate);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 metaNodeReward);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event RequestUnstake(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 blockNumber);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event MetaNodeTransfer(address indexed to, uint256 amount);

    modifier checkPid(uint256 _pid) {
        require(_pid < pools.length, "Invalid pool id");
        _;
    }
    // 要求提现开启
    modifier whenNotWithdrawPaused() {
        require(!withdrawEnabled, "Withdraw is paused");
        _;
    }

    modifier whenNotClaimPaused() {
        require(!claimEnabled, "claim is paused");
        _;
    }

    function initialize(
        IERC20 _tokenAddress,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _tokensPerBlock
    ) public initializer {
        __AccessControl_init();  // 访问控制初始化
        __UUPSUpgradeable_init(); // 升级合约
        __Pausable_init(); //暂停或启动合约功能
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // 设置默认管理员角色
        _grantRole(ADMIN_ROLE, msg.sender); // 设置管理员角色
        _grantRole(UPGRADE_ROLE, msg.sender); // 设置升级角色

        setToken(_tokenAddress);
        startBlock = _startBlock;
        endBlock = _endBlock;
        tokensPerBlock = _tokensPerBlock;
    }

    function setToken(IERC20 _token) public  onlyRole(ADMIN_ROLE) {
        token = _token;
    }

    //管理员可升级合约
    function _authorizeUpgrade(address newImplementation) internal onlyRole(ADMIN_ROLE) override {
        // Add access control logic here
    }

    //停止提现
    function stopWithdraw() public onlyRole(ADMIN_ROLE) {
        require(!withdrawEnabled, "Withdraw is already disabled");

        withdrawEnabled = true;
        emit WithdrawStopped();
    }
    //开启提现
    function startWithdraw() public onlyRole(ADMIN_ROLE) {
        require(withdrawEnabled, "Withdraw is already enabled");

        withdrawEnabled = false;
        emit WithdrawStarted();
    }
    //停止领取
    function stopClaim() public onlyRole(ADMIN_ROLE) {
        require(!claimEnabled, "Claim is already disabled");
        claimEnabled = true;
        emit ClaimStopped();
    }
    //开启领取
    function startClaim() public onlyRole(ADMIN_ROLE) {
        require(claimEnabled, "Claim is already enabled");
        claimEnabled = false;
        emit ClaimStarted();    
    }
    //设置开始区块
    function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
        require(startBlock <= endBlock, "endBlockmust be greater than startBlock");
        startBlock = _startBlock;
        emit StartBlockSet(_startBlock);
    }
    //设置结束区块
    function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
        require(endBlock >= startBlock, "endBlock must be greater than startBlock");
        endBlock = _endBlock;
        emit EndBlockSet(_endBlock);
    }
    // 设置每块奖励代币数量
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyRole(ADMIN_ROLE) {
        require(_tokensPerBlock > 0, "Tokens per block must be greater than 0");
        tokensPerBlock = _tokensPerBlock;
        emit TokensPerBlockSet(_tokensPerBlock);
    }
    // 添加质押池
    function addPool(
        address _stTokenAddress,    //质押代币地址
        uint256 _poolWeight, //质押池权重
        uint256 _minDepositAmount, //最小质押金额
        uint256 _unstakeLockedBlocks, //解除质押的锁定区块数
        bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) {
        //第一个地址为ETH质押池，不需要质押代币地址
        if (pools.length > 0) {
            require(_stTokenAddress != address(0x0), "Invalid stToken address");
        }else {
            require(_stTokenAddress == address(0x0), "Invalid stToken address");
        }
        
        require(_poolWeight > 0, "Pool weight must be greater than 0");
        require(_minDepositAmount > 0, "Min deposit amount must be greater than 0");
        
        if(_withUpdate){//结算已有质押池奖励
            massUpdatePools();
        }
        
        totalWeight += _poolWeight; //增加总权重
        
        pools.push(
            Pool({
                stTokenAddress: _stTokenAddress,
                poolWeight: _poolWeight,
                lastRewardBlock: block.number > startBlock ? block.number : startBlock,
                accMetaNodePerST: 0,
                stTokenAmount: 0,
                minDepositAmount: _minDepositAmount,
                unstakeLockedBlocks: _unstakeLockedBlocks
            })
        );
        emit PoolAdded(pools.length - 1, _stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    }

    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    //设置质押池权重
    function setPoolWeight(
        uint256 _pid,
        uint256 _poolWeight,
        bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
        require(_poolWeight > 0, "Pool weight must be greater than 0");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalWeight = totalWeight - pools[_pid].poolWeight + _poolWeight;
        pools[_pid].poolWeight = _poolWeight;

        emit PoolWeightSet(_pid, _poolWeight, _withUpdate);
    }

    //更新质押池
    function updatePool(
        uint256 _pid,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) public onlyRole(ADMIN_ROLE) checkPid(_pid){
        require(_minDepositAmount > 0, "Min deposit amount must be greater than 0");

        pools[_pid].minDepositAmount = _minDepositAmount;
        pools[_pid].unstakeLockedBlocks = _unstakeLockedBlocks;
        emit PoolUpdated(_pid, _minDepositAmount, _unstakeLockedBlocks);
    }
    //获取区间总奖励
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256 multiplier){
        require(_to >= _from, "Invalid block range");
        if(_from > startBlock ){
            _from = startBlock;
        }
        if(_to > endBlock){
            _to = endBlock;
        }
        require(_to >= _from, "Invalid block range");
        bool success;
        (success,multiplier) = (_to - _from).tryMul(tokensPerBlock);
        require(success, "Overflow");
    }

    //更新质押池奖励
    function updatePool(uint256 _pid) public checkPid(_pid) {
        Pool storage pool_ = pools[_pid];

        if (block.number <= pool_.lastRewardBlock) {
            return;
        }

        (bool success1, uint256 totalMetaNode) = getMultiplier(
            pool_.lastRewardBlock,
            block.number
        ).tryMul(pool_.poolWeight);
        require(success1, "overflow");

        (success1, totalMetaNode) = totalMetaNode.tryDiv(totalWeight);
        require(success1, "overflow");

        uint256 stSupply = pool_.stTokenAmount;
        if (stSupply > 0) {
            (bool success2, uint256 totalMetaNode_) = totalMetaNode.tryMul(
                1 ether
            );
            require(success2, "overflow");

            (success2, totalMetaNode_) = totalMetaNode_.tryDiv(stSupply);
            require(success2, "overflow");

            (bool success3, uint256 accMetaNodePerST) = pool_
                .accMetaNodePerST
                .tryAdd(totalMetaNode_);
            require(success3, "overflow");
            pool_.accMetaNodePerST = accMetaNodePerST;
        }

        pool_.lastRewardBlock = block.number;

        emit UpdatePool(_pid, pool_.lastRewardBlock, totalMetaNode);
    }
    //批量更新所有质押池奖励
    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }
    //获取用户待领取的代币数量
    function pendingMetaNode(
        uint256 _pid,
        address _user
    ) external view checkPid(_pid) returns (uint256){
        return pendingMetaNode(_pid, _user, block.number);
    }

    //获取用户待领取的代币数量（私有函数）
    function pendingMetaNode(
        uint256 _pid,
        address _user,
        uint256 blockNumber
    ) private view checkPid(_pid) returns (uint256){
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][_user];
        uint256 accMetaNodePerST = pool_.accMetaNodePerST;
        uint256 stSupply = pool_.stTokenAmount;

        if (blockNumber >= pool_.lastRewardBlock && pool_.stTokenAmount != 0){
            uint256 totalMetaNode = getMultiplier(
                pool_.lastRewardBlock,
                blockNumber
            );
            
            accMetaNodePerST += (totalMetaNode * pool_.poolWeight * 1 ether) / (totalWeight * stSupply);
        }

        return user_.stAmount * accMetaNodePerST / 1 ether - user_.finishedMetaNode + user_.pendingMetaNode;
    }
    // 获取用户质押的代币数量
    function stakingBalance(
        uint256 _pid,
        address _user
    ) external view checkPid(_pid) returns (uint256){
        return users[_pid][_user].stAmount;
    }
    // 质押ETH
    function depositETH() public payable whenNotPaused{
        require(msg.value > 0, "Deposit amount must be greater than 0");
        Pool storage pool_ = pools[ETH_PID];
        require(
            msg.value >= pool_.minDepositAmount,
            "Deposit amount must be greater than min deposit amount"
        );
        deposit(ETH_PID, msg.value);
    }
    // 质押代币
    function depositTokens(
        uint256 _pid,
        uint256 _amount
    ) public whenNotPaused checkPid(_pid) {
        Pool storage pool_ = pools[_pid];
        require(
            _amount >= pool_.minDepositAmount,
            "Deposit amount must be greater than min deposit amount"
        );
        require(
            IERC20(pool_.stTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Transfer failed"
        );

        deposit(_pid, _amount);
    }  
    // 取消质押
    function unstake(
        uint256 _pid,
        uint256 _amount
    )public whenNotPaused checkPid(_pid) {
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][msg.sender];

        require(user_.stAmount >= _amount, "Not enough staking token balance");
        //更新池子
        updatePool(_pid);
        //计算用户待领取奖励 用户质押数量 * 池子每份代币奖励 / 1e18 - 用户已领取奖励
        uint256 pendingMetaNode_ = (user_.stAmount * pool_.accMetaNodePerST) /
            (1 ether) -
            user_.finishedMetaNode;

        if (pendingMetaNode_ > 0) {
            user_.pendingMetaNode = user_.pendingMetaNode + pendingMetaNode_;
        }
        // 减少用户和池子质押数量 等待释放
        if (_amount > 0) {
            user_.stAmount = user_.stAmount - _amount;
            user_.requests.push(
                UnStakeRequest({
                    amount: _amount,
                    unlockBlocks: block.number + pool_.unstakeLockedBlocks
                })
            );
            pool_.stTokenAmount = pool_.stTokenAmount - _amount;
        }

        user_.finishedMetaNode =
            (user_.stAmount * pool_.accMetaNodePerST) /
            (1 ether);

        emit RequestUnstake(msg.sender, _pid, _amount);
    } 
    // 提现
    function withdraw(
        uint256 _pid
    ) public whenNotPaused checkPid(_pid) whenNotWithdrawPaused{
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][msg.sender];

        uint256 pendingWithdraw_;
        uint256 popNum_;
        for (uint256 i = 0; i < user_.requests.length; i++) {
            if (user_.requests[i].unlockBlocks > block.number) {
                break;
            }
            pendingWithdraw_ = pendingWithdraw_ + user_.requests[i].amount;
            popNum_++;
        }

        for (uint256 i = 0; i < user_.requests.length - popNum_; i++) {
            user_.requests[i] = user_.requests[i + popNum_];
        }

        for (uint256 i = 0; i < popNum_; i++) {
            user_.requests.pop();
        }

        if (pendingWithdraw_ > 0) {
            if (pool_.stTokenAddress == address(0x0)) {
                _safeETHTransfer(msg.sender, pendingWithdraw_);
            } else {
                IERC20(pool_.stTokenAddress).safeTransfer(
                    msg.sender,
                    pendingWithdraw_
                );
            }
        }

        emit Withdraw(msg.sender, _pid, pendingWithdraw_, block.number);

    }
    //  领取奖励
    function claim(
        uint256 _pid
    ) public whenNotPaused checkPid(_pid) whenNotClaimPaused {
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][msg.sender];

        updatePool(_pid);

        uint256 pendingMetaNode_ = (user_.stAmount * pool_.accMetaNodePerST) /
            (1 ether) -
            user_.finishedMetaNode +
            user_.pendingMetaNode;

        if (pendingMetaNode_ > 0) {
            user_.pendingMetaNode = 0;
            _safeMetaNodeTransfer(msg.sender, pendingMetaNode_);
        }

        user_.finishedMetaNode =
            (user_.stAmount * pool_.accMetaNodePerST) /
            (1 ether);

        emit Claim(msg.sender, _pid, pendingMetaNode_);
    }



    // 质押
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) public whenNotPaused checkPid(_pid) {
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][msg.sender];
        //更新池子
        updatePool(_pid);
        //计算用户待领取奖励 用户质押数量 * 池子每份代币奖励 / 1e18 - 用户已领取奖励
        if (user_.stAmount > 0) {
            
            (bool success1, uint256 accST) = user_.stAmount.tryMul(
                pool_.accMetaNodePerST
            );
            require(success1, "user stAmount mul accMetaNodePerST overflow");
            (success1, accST) = accST.tryDiv(1 ether);
            require(success1, "accST div 1 ether overflow");

            (bool success2, uint256 pendingMetaNode_) = accST.trySub(
                user_.finishedMetaNode
            );
            require(success2, "accST sub finishedMetaNode overflow");

            if (pendingMetaNode_ > 0) {
                (bool success3, uint256 _pendingMetaNode) = user_
                    .pendingMetaNode
                    .tryAdd(pendingMetaNode_);
                require(success3, "user pendingMetaNode overflow");
                user_.pendingMetaNode = _pendingMetaNode;
            }
        }
        // 增加用户和池子质押数量
        if (_amount > 0) {
            (bool success4, uint256 stAmount) = user_.stAmount.tryAdd(_amount);
            require(success4, "user stAmount overflow");
            user_.stAmount = stAmount;

            (bool success5, uint256 stTokenAmount) = pool_.stTokenAmount.tryAdd(
            _amount
            );
            require(success5, "pool stTokenAmount overflow");
            pool_.stTokenAmount = stTokenAmount;
        }

        // 更新用户已完结奖励
        (bool success6, uint256 finishedMetaNode) = user_.stAmount.tryMul(
            pool_.accMetaNodePerST
        );
        require(success6, "user stAmount mul accMetaNodePerST overflow");

        (success6, finishedMetaNode) = finishedMetaNode.tryDiv(1 ether);
        require(success6, "finishedMetaNode div 1 ether overflow");

        user_.finishedMetaNode = finishedMetaNode;

        emit Deposit(msg.sender, _pid, _amount);
    }
    // 安全提取ETH
    function _safeETHTransfer(address _to, uint256 _amount) internal{
       (bool success,bytes memory data) = address(_to).call{value : _amount}("");
       require(success && (data.length == 0 || abi.decode(data, (bool))),"ETH transfer failed");
    }
    // 安全提取代币
    function _safeMetaNodeTransfer(
        address _to,
        uint256 _amount
    ) internal {
        //uint256 metaNodeBal = token.balanceOf(address(this));
        //require(metaNodeBal >= _amount, "No MetaNode to transfer");
        
        require(token.transfer(_to, _amount), "Transfer failed");
        emit MetaNodeTransfer(_to, _amount);
    }

}