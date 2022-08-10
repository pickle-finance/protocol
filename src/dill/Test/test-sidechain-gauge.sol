// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
import {ProtocolGovernance, Math, ReentrancyGuard, SafeERC20, IERC20} from "../gauge-proxy-v2.sol";

contract TestSideChainGauge is ProtocolGovernance, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constant for various precisions
    uint256 private constant _MultiplierPrecision = 1e18;

    IERC20 public immutable TOKEN;
    // NOTES: here distribution is offline relayer.
    address public immutable DISTRIBUTION;
    IERC20 public PICKLE;
    uint256 public constant DURATION = 7 days;

    // Lock time and multiplier
    uint256 public lockMaxMultiplier = uint256(25e17); // E18. 1x = e18
    uint256 public lockTimeForMaxMultiplier = 365 * 86400; // 1 year
    uint256 public lockTimeMin = 86400; // 1 day

    //Reward addresses, rates, and symbols
    uint256 public rewardRates;

    // Time tracking
    uint256 public periodFinish = 0;
    uint256 public lastUpdateTime;

    // Rewards tracking
    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) public _rewards;
    uint256 private rewardPerTokenStored;
    uint256 public multiplierDecayPerSecond = uint256(48e9);
    mapping(address => mapping(uint256 => uint256)) private _lastUsedMultiplier;
    mapping(address => uint256) private _lastRewardClaimTime; // staker addr -> timestamp

    // Balance tracking
    uint256 private _totalSupply;
    uint256 public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;

    // Delegate tracking
    mapping(address => mapping(address => bool)) public stakingDelegates;

    // Stake tracking
    mapping(address => LockedStake[]) private _lockedStakes;

    // Administrative booleans
    bool public stakesUnlocked; // Release locked stakes in case of emergency
    mapping(address => bool) public stakesUnlockedForAccount; // Release locked stakes of an account in case of emergency

    /* ========== STRUCTS ========== */

    struct LockedStake {
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier;
        bool isPermanentlyLocked;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyDistribution() {
        require(
            msg.sender == DISTRIBUTION,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    modifier onlyGov() {
        require(
            msg.sender == governance,
            "Operation allowed by only governance"
        );
        _;
    }

    modifier lockable(uint256 secs) {
        require(secs >= lockTimeMin, "Minimum stake time not met");
        require(
            secs <= lockTimeForMaxMultiplier,
            "Trying to lock for too long"
        );
        _;
    }

    modifier updateReward(address account, bool isClaimReward) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            uint256 earnedRewards = earned(account);
            _rewards[account] = earnedRewards;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
            if (isClaimReward) {
                _lastRewardClaimTime[account] = block.timestamp;
            }
        }
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _token,
        address _pickle,
        address _governance,
        address _distribution
    ) {
        TOKEN = IERC20(_token);
        PICKLE = IERC20(_pickle);
        DISTRIBUTION = _distribution;
        governance = _governance;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRates *
                1e18) / derivedSupply);
    }

    // All the locked stakes for a given account
    function lockedStakesOf(address account)
        external
        view
        returns (LockedStake[] memory)
    {
        return _lockedStakes[account];
    }

    function earned(address account) public view returns (uint256 newEarned) {
        uint256 reward = rewardPerToken();
        if (derivedBalances[account] == 0) {
            newEarned = 0;
        } else {
            newEarned =
                ((derivedBalances[account] *
                    (reward - userRewardPerTokenPaid[account])) / 1e18) +
                _rewards[account];
        }
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRates * DURATION;
    }

    // Multiplier amount, given the length of the lock
    function lockMultiplier(uint256 secs) public view returns (uint256) {
        uint256 lock_multiplier = uint256(_MultiplierPrecision) +
            ((secs * (lockMaxMultiplier - _MultiplierPrecision)) /
                (lockTimeForMaxMultiplier));
        if (lock_multiplier > lockMaxMultiplier)
            lock_multiplier = lockMaxMultiplier;
        return lock_multiplier;
    }

    function _averageDecayedLockMultiplier(
        address account,
        uint256 index,
        uint256 elapsedSeconds
    ) internal view returns (uint256) {
        return
            (2 *
                _lastUsedMultiplier[account][index] -
                (elapsedSeconds - 1) *
                multiplierDecayPerSecond) / 2;
    }

    function setStakingDelegate(address _delegate) public {
        require(
            stakingDelegates[msg.sender][_delegate],
            "Already a staking delegate for user!"
        );
        require(_delegate != msg.sender, "Cannot delegate to self");
        stakingDelegates[msg.sender][_delegate] = true;
    }

    function derivedBalance(address account) public returns (uint256) {
        // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
        uint256 lockBoostedDerivedBal = 0;
        for (uint256 i = 0; i < _lockedStakes[account].length; i++) {
            LockedStake memory thisStake = _lockedStakes[account][i];
            uint256 lock_multiplier = thisStake.lock_multiplier;
            uint256 lastRewardClaimTime = _lastRewardClaimTime[account];
            // If the lock is expired
            if (
                thisStake.ending_timestamp <= block.timestamp &&
                !thisStake.isPermanentlyLocked
            ) {
                // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
                if (lastRewardClaimTime < thisStake.ending_timestamp) {
                    uint256 timeBeforeExpiry = thisStake.ending_timestamp -
                        lastRewardClaimTime;
                    uint256 timeAfterExpiry = block.timestamp -
                        thisStake.ending_timestamp;

                    // Get the weighted-average lock_multiplier
                    uint256 numerator = (lock_multiplier * timeBeforeExpiry) +
                        (_MultiplierPrecision * timeAfterExpiry);
                    lock_multiplier =
                        numerator /
                        (timeBeforeExpiry + timeAfterExpiry);
                }
                // Otherwise, it needs to just be 1x
                else {
                    lock_multiplier = _MultiplierPrecision;
                }
            } else {
                uint256 elapsedSeconds = block.timestamp - lastRewardClaimTime;
                if (elapsedSeconds > 0) {
                    lock_multiplier = thisStake.isPermanentlyLocked
                        ? lockMaxMultiplier
                        : _averageDecayedLockMultiplier(
                            account,
                            i,
                            elapsedSeconds
                        );
                    _lastUsedMultiplier[account][i] =
                        _lastUsedMultiplier[account][i] -
                        (elapsedSeconds - 1) *
                        multiplierDecayPerSecond;
                }
            }
            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = (liquidity * lock_multiplier) /
                _MultiplierPrecision;
            lockBoostedDerivedBal =
                lockBoostedDerivedBal +
                combined_boosted_amount;
        }

        return lockBoostedDerivedBal;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function kick(address account) public {
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply - _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply + _derivedBalance;
    }

    function depositAllAndLock(uint256 secs, bool isPermanentlyLocked)
        external
        lockable(secs)
    {
        _deposit(
            TOKEN.balanceOf(msg.sender),
            msg.sender,
            secs,
            block.timestamp,
            isPermanentlyLocked
        );
    }

    function depositForAndLock(
        uint256 amount,
        address account,
        uint256 secs,
        bool isPermanentlyLocked
    ) external lockable(secs) {
        require(
            stakingDelegates[account][msg.sender],
            "Only registerd delegates can stake for their deligator"
        );
        _deposit(amount, account, secs, block.timestamp, isPermanentlyLocked);
    }

    function depositAndLock(
        uint256 amount,
        uint256 secs,
        bool isPermanentlyLocked
    ) external lockable(secs) {
        _deposit(
            amount,
            msg.sender,
            secs,
            block.timestamp,
            isPermanentlyLocked
        );
    }

    function _deposit(
        uint256 amount,
        address account,
        uint256 secs,
        uint256 start_timestamp,
        bool isPermanentlyLocked
    ) internal nonReentrant updateReward(account, false) {
        require(amount > 0, "Cannot stake 0");
        uint256 MaxMultiplier = lockMultiplier(secs);
        _lockedStakes[account].push(
            LockedStake(
                start_timestamp,
                amount,
                start_timestamp + secs,
                MaxMultiplier,
                isPermanentlyLocked
            )
        );
        _lastUsedMultiplier[account][
            _lockedStakes[account].length - 1
        ] = MaxMultiplier;

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;

        // Needed for edge case if the staker only claims once, and after the lock expired
        if (_lastRewardClaimTime[account] == 0)
            _lastRewardClaimTime[account] = block.timestamp;

        TOKEN.safeTransferFrom(account, address(this), amount);
        emit Staked(account, amount, secs, _lockedStakes[account].length - 1);
    }

    function withdraw(uint256 index) external {
        _withdraw(index);
    }

    function withdrawAll() public {
        uint256 amount = _partialWithdrawal(msg.sender, _balances[msg.sender]);
        emit WithdrawnAll(msg.sender, amount);
    }

    function partialWithdrawal(uint256 _amount) external {
        uint256 amount = _partialWithdrawal(msg.sender, _amount);
        emit WithdrawnPartilly(msg.sender, amount);
    }

    function _partialWithdrawal(address _account, uint256 _amount)
        internal
        nonReentrant
        updateReward(_account, false)
        returns (uint256)
    {
        require(
            _amount <= _balances[_account],
            "Withdraw amount exceeds balance"
        );
        uint256 amountToTransfer = 0;
        for (uint256 i = 0; i < _lockedStakes[_account].length; i++) {
            LockedStake memory thisStake = _lockedStakes[_account][i];
            // check if stake is not locked
            uint256 amountRemaining = _amount - amountToTransfer;
            if (
                thisStake.liquidity > 0 &&
                (stakesUnlocked ||
                    stakesUnlockedForAccount[_account] ||
                    (!thisStake.isPermanentlyLocked &&
                        block.timestamp >= thisStake.ending_timestamp))
            ) {
                if (thisStake.liquidity < amountRemaining) {
                    amountToTransfer += thisStake.liquidity;
                    delete _lockedStakes[_account][i];
                } else if (thisStake.liquidity == amountRemaining) {
                    amountToTransfer += thisStake.liquidity;
                    delete _lockedStakes[_account][i];
                    break;
                } else if (thisStake.liquidity > amountRemaining) {
                    _lockedStakes[_account][i].liquidity -= amountRemaining;
                    amountToTransfer = _amount;
                    break;
                }
            }
        }
        if (amountToTransfer > 0) {
            _totalSupply = _totalSupply - amountToTransfer;
            _balances[_account] = _balances[_account] - amountToTransfer;
            TOKEN.safeTransfer(msg.sender, amountToTransfer);
        }
        return amountToTransfer;
    }

    function _withdraw(uint256 index)
        internal
        nonReentrant
        updateReward(msg.sender, false)
    {
        LockedStake memory thisStake;
        thisStake.liquidity = 0;
        require(index < _lockedStakes[msg.sender].length, "Stake not found");

        thisStake = _lockedStakes[msg.sender][index];

        require(
            stakesUnlocked ||
                stakesUnlockedForAccount[msg.sender] ||
                (
                    thisStake.isPermanentlyLocked
                        ? false
                        : block.timestamp >= thisStake.ending_timestamp
                ),
            "Stake is still locked!"
        );

        uint256 liquidity = thisStake.liquidity;

        if (liquidity > 0) {
            _totalSupply = _totalSupply - liquidity;
            _balances[msg.sender] = _balances[msg.sender] - liquidity;
            delete _lockedStakes[msg.sender][index];
            TOKEN.safeTransfer(msg.sender, liquidity);
            emit Withdrawn(msg.sender, liquidity, index);
        }
    }

    function getReward() public nonReentrant updateReward(msg.sender, true) {
        uint256 reward;
        reward = _rewards[msg.sender];
        if (reward > 0) {
            _rewards[msg.sender] = 0;
            IERC20(PICKLE).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdrawAll();
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount()
        external
        onlyDistribution
        updateReward(address(0), false)
    {
        uint256 amount = IERC20(PICKLE).balanceOf(address(this));
        if (block.timestamp >= periodFinish) {
            rewardRates = amount / DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRates;
            rewardRates = (amount + leftover) / DURATION;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        emit RewardAdded(amount);
    }

    function setMultipliers(uint256 _lock_max_multiplier) external onlyGov {
        require(
            _lock_max_multiplier >= uint256(1e18),
            "Multiplier must be greater than or equal to 1e18"
        );
        lockMaxMultiplier = _lock_max_multiplier;
        emit LockedStakeMaxMultiplierUpdated(lockMaxMultiplier);
    }

    function setMaxRewardsDuration(uint256 _lockTimeForMaxMultiplier)
        external
        onlyGov
    {
        require(
            _lockTimeForMaxMultiplier >= 86400,
            "Rewards duration too short"
        );
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Reward period incomplete"
        );
        lockTimeForMaxMultiplier = _lockTimeForMaxMultiplier;
        emit MaxRewardsDurationUpdated(lockTimeForMaxMultiplier);
    }

    function unlockStakes() external onlyGov {
        stakesUnlocked = !stakesUnlocked;
    }

    function unlockStakeForAccount(address account) external onlyGov {
        stakesUnlockedForAccount[account] = !stakesUnlockedForAccount[account];
    }

    /* ========== EVENTS ========== */
    event approvedTokenReceipt(address _spender, uint256 _amount);
    event stakeTransferd(address _to, uint256 _index);
    event allStakesTransferd(address _to);
    event RewardAdded(uint256 reward);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 secs,
        uint256 index
    );
    event Withdrawn(address indexed user, uint256 amount, uint256 index);
    event WithdrawnAll(address indexed user, uint256 amount);
    event WithdrawnPartilly(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
    event MaxRewardsDurationUpdated(uint256 newDuration);
}
