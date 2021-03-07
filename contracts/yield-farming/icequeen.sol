pragma solidity 0.6.7;

import "../lib/enumerableSet.sol";
import "../lib/safe-math.sol";
import "../lib/erc20.sol";
import "../lib/ownable.sol";
import "./snowball.sol";

// IceQueen is the ultimate snowball maker. She can gift her snowballs to her subjects and is a fair ruler.
//
// Note that the IceQueen is ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SNOB (snowball) is sufficiently
// distributed and the community can be shown to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract IceQueen is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SNOB
        // entitled to a user but is pending to be distributed as:
        //
        //   pending reward = (user.amount * pool.accSnowballPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSnowballPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SNOB to distribute per block.
        uint256 lastRewardBlock; // Last block number that SNOB distribution occurs.
        uint256 accSnowballPerShare; // Accumulated SNOB per share, times 1e12. See below.
    }

    // The SNOWBALL TOKEN!
    Snowball public snowball;
    // Dev fund (10% initially)
    uint256 public devFundDivRate = 10;
    // Dev address.
    address public devfund;
    // Treasury fund (10% initially)
    uint256 public treasuryDivRate = 10;
    // Treasury address.
    address public treasury;
    // Block number when bonus SNOB period ends.
    uint256 public bonusEndBlock;
    // SNOB tokens created per block.
    uint256 public snowballPerBlock;
    // Bonus muliplier for early snowball makers.
    uint256 public bonusMultiplier = 5;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SNOB mining starts.
    uint256 public startBlock;

    // Events
    event Recovered(address token, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        Snowball _snowball,
        address _devfund,
        address _treasury,
        uint256 _snowballPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        snowball = _snowball;
        devfund = _devfund;
        treasury = _treasury;
        snowballPerBlock = _snowballPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSnowballPerShare: 0
            })
        );
    }

    // Update the given pool's SNOB allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            updatePool(_pid);
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    function setMultiplier(uint256 _mult) public onlyOwner {
        bonusMultiplier = _mult;
    }

    // View function to see pending SNOB on frontend.
    function pendingSnowball(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSnowballPerShare = pool.accSnowballPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 snowballReward = multiplier
                .mul(snowballPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accSnowballPerShare = accSnowballPerShare.add(
                snowballReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accSnowballPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 snowballReward = multiplier
            .mul(snowballPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        snowball.mint(devfund, snowballReward.div(devFundDivRate));
        snowball.mint(treasury, snowballReward.div(treasuryDivRate));
        snowball.mint(address(this), snowballReward);
        pool.accSnowballPerShare = pool.accSnowballPerShare.add(
            snowballReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to IceQueen for SNOB allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accSnowballPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeSnowballTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSnowballPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from IceQueen.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSnowballPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeSnowballTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSnowballPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe snowball transfer function, just in case if rounding error causes pool to not have enough SNOB.
    function safeSnowballTransfer(address _to, uint256 _amount) internal {
        uint256 snowballBal = snowball.balanceOf(address(this));
        if (_amount > snowballBal) {
            snowball.transfer(_to, snowballBal);
        } else {
            snowball.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function updateDevfund(address _devfund) public {
        require(msg.sender == devfund, "dev: wut?");
        devfund = _devfund;
    }

    // Update treasury address by the previous dev.
    function updateTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;
    }

    // **** Additional functions separate from the original icequeen contract ****

    function setSnowballPerBlock(uint256 _snowballPerBlock) public onlyOwner {
        require(_snowballPerBlock > 0, "!snowballPerBlock-0");

        snowballPerBlock = _snowballPerBlock;
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
        require(_devFundDivRate > 0, "!devFundDivRate-0");
        devFundDivRate = _devFundDivRate;
    }

    function setTreasuryDivRate(uint256 _treasuryDivRate) public onlyOwner {
        require(_treasuryDivRate > 0, "!treasuryDivRate-0");
        treasuryDivRate = _treasuryDivRate;
    }
}
