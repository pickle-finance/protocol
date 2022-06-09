// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1; // ^0.6.7; //^0.7.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        // return address(uint160(account));
        return payable(address(uint160(account)));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) +
            (value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) -
            (
                value
                // ,
                // "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    // constructor() public {
    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract ProtocolGovernance {
    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(
            msg.sender == pendingGovernance,
            "acceptGovernance: !pendingGov"
        );
        governance = pendingGovernance;
    }
}

contract GaugeV2 is ProtocolGovernance, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Token addresses
    IERC20 public constant PICKLE =
        IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);
    IERC20 public constant DILL =
        IERC20(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf);
    address public constant TREASURY =
        address(0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3);

    // Constant for various precisions
    uint256 private constant MULTIPLIER_PRECISION = 1e18;

    IERC20 public immutable TOKEN;
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    // Lock time and multiplier settings
    uint256 public lock_max_multiplier = uint256(25e17); // E18. 1x = e18
    uint256 public lock_time_for_max_multiplier = 1 * 365 * 86400; // 1 year
    uint256 public lock_time_min = 86400; // 1 * 86400  (1 day)

    // Time tracking
    uint256 public periodFinish = 0;
    uint256 public lastUpdateTime;

    // Rewards tracking
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate = 0;
    uint256 public multiplierDecayPerPeriod = uint256(2876712e10);
    mapping(address => uint256) private lastusedMultiplier;
    mapping(address => uint256) private lastRewardClaimTime; // staker addr -> timestamp

    // Balance tracking
    uint256 private _totalSupply;
    uint256 public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;
    mapping(address => uint256) private _base;

    // Stake tracking
    mapping(address => LockedStake[]) private lockedStakes;

    // Administrative booleans
    bool public stakesUnlocked; // Release locked stakes in case of emergency
    mapping(address => bool) public stakesUnlockedForAccount; // Release locked stakes of an account in case of emergency

    /* ========== STRUCTS ========== */

    struct LockedStake {
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
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
        require(secs >= lock_time_min, "Minimum stake time not met");
        require(
            secs <= lock_time_for_max_multiplier,
            "Trying to lock for too long"
        );
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
        }
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _token, address _governance) {
        TOKEN = IERC20(_token);
        DISTRIBUTION = msg.sender;
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
                rewardRate *
                1e18) / derivedSupply);
    }

    // All the locked stakes for a given account
    function lockedStakesOf(address account)
        external
        view
        returns (LockedStake[] memory)
    {
        return lockedStakes[account];
    }

    function earned(address account) public view returns (uint256) {
        return
            ((derivedBalances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * DURATION;
    }

    // Multiplier amount, given the length of the lock
    function lockMultiplier(uint256 secs) public view returns (uint256) {
        uint256 lock_multiplier = uint256(MULTIPLIER_PRECISION) +
            ((secs * (lock_max_multiplier - MULTIPLIER_PRECISION)) /
                (lock_time_for_max_multiplier));
        if (lock_multiplier > lock_max_multiplier)
            lock_multiplier = lock_max_multiplier;
        return lock_multiplier;
    }

    function _decayedLockMultiplier(address account, uint256 elapsedPeriods)
        internal
        view
        returns (uint256)
    {
        return
            (lastusedMultiplier[account] +
                (elapsedPeriods - 1) *
                multiplierDecayPerPeriod) / 2;
    }

    function derivedBalance(address account) public returns (uint256) {
        uint256 _balance = _balances[account];
        uint256 _derived = (_balance * 40) / 100;
        uint256 _adjusted = (((_totalSupply * DILL.balanceOf(account)) /
            DILL.totalSupply()) * 60) / 100;
        uint256 dillBoostedDerivedBal = Math.min(
            _derived + _adjusted,
            _balance
        );

        // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
        uint256 lockBoostedDerivedBal = 0;
        for (uint256 i = 0; i < lockedStakes[account].length; i++) {
            LockedStake memory thisStake = lockedStakes[account][i];
            uint256 lock_multiplier = thisStake.lock_multiplier;

            // If the lock is expired
            if (thisStake.ending_timestamp <= block.timestamp) {
                // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
                if (lastRewardClaimTime[account] < thisStake.ending_timestamp) {
                    uint256 time_before_expiry = thisStake.ending_timestamp -
                        lastRewardClaimTime[account];
                    uint256 time_after_expiry = block.timestamp -
                        thisStake.ending_timestamp;

                    // Get the weighted-average lock_multiplier
                    uint256 numerator = (lock_multiplier * time_before_expiry) +
                        (MULTIPLIER_PRECISION * time_after_expiry);
                    lock_multiplier =
                        numerator /
                        (time_before_expiry + time_after_expiry);
                }
                // Otherwise, it needs to just be 1x
                else {
                    lock_multiplier = MULTIPLIER_PRECISION;
                }
            } else {
                uint256 elapsedPeriods = (block.timestamp - lastUpdateTime) / 7;
                if (elapsedPeriods > 0) {
                    lock_multiplier = _decayedLockMultiplier(
                        account,
                        elapsedPeriods
                    );
                    lastusedMultiplier[account] = lock_multiplier;
                }
            }

            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = (liquidity * lock_multiplier) /
                MULTIPLIER_PRECISION;
            lockBoostedDerivedBal =
                lockBoostedDerivedBal +
                combined_boosted_amount;
        }

        return dillBoostedDerivedBal + lockBoostedDerivedBal;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function kick(address account) public {
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply - _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply + _derivedBalance;
    }

    function depositAllAndLock(uint256 secs) external lockable(secs) {
        _deposit(
            TOKEN.balanceOf(msg.sender),
            msg.sender,
            secs,
            block.timestamp
        );
    }

    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender, 0, block.timestamp);
    }

    function depositFor(uint256 amount, address account) external {
        _deposit(amount, account, 0, block.timestamp);
    }

    function depositForAndLock(
        uint256 amount,
        address account,
        uint256 secs
    ) external lockable(secs) {
        _deposit(amount, account, secs, block.timestamp);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender, 0, block.timestamp);
    }

    function depositAndLock(uint256 amount, uint256 secs)
        external
        lockable(secs)
    {
        _deposit(amount, msg.sender, secs, block.timestamp);
    }

    function _deposit(
        uint256 amount,
        address account,
        uint256 secs,
        uint256 start_timestamp
    ) internal nonReentrant updateReward(account) {
        require(amount > 0, "Cannot stake 0");
        lastusedMultiplier[account] = lockMultiplier(secs);
        lockedStakes[account].push(
            LockedStake(
                start_timestamp,
                amount,
                start_timestamp + secs,
                lastusedMultiplier[account]
            )
        );

        TOKEN.safeTransferFrom(account, address(this), amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;

        // Needed for edge case if the staker only claims once, and after the lock expired
        if (lastRewardClaimTime[account] == 0)
            lastRewardClaimTime[account] = block.timestamp;

        emit Staked(account, amount, secs, lockedStakes[account].length - 1);
    }

    function withdraw(uint256 index) external {
        _withdraw(index);
    }

    function withdrawAll() public nonReentrant updateReward(msg.sender) {
        for (uint256 i = 0; i < lockedStakes[msg.sender].length; i++) {
            uint256 liquidity = lockedStakes[msg.sender][i].liquidity;
            if (liquidity > 0) {
                _totalSupply = _totalSupply - liquidity;
                _balances[msg.sender] = _balances[msg.sender] - liquidity;
                delete lockedStakes[msg.sender][i];
                TOKEN.safeTransfer(msg.sender, liquidity);
                emit Withdrawn(msg.sender, liquidity, i);
            }
        }
    }

    function _withdraw(uint256 index)
        internal
        nonReentrant
        updateReward(msg.sender)
    {
        LockedStake memory thisStake;
        thisStake.liquidity = 0;
        require(index < lockedStakes[msg.sender].length, "Stake not found");

        thisStake = lockedStakes[msg.sender][index];

        require(
            block.timestamp >= thisStake.ending_timestamp ||
                stakesUnlocked == true ||
                stakesUnlockedForAccount[msg.sender] == true,
            "Stake is still locked!"
        );

        uint256 liquidity = thisStake.liquidity;

        if (liquidity > 0) {
            _totalSupply = _totalSupply - liquidity;
            _balances[msg.sender] = _balances[msg.sender] - liquidity;
            delete lockedStakes[msg.sender][index];
            TOKEN.safeTransfer(msg.sender, liquidity);
        }

        emit Withdrawn(msg.sender, liquidity, index);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            PICKLE.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }

        lastRewardClaimTime[msg.sender] = block.timestamp;
    }

    function exit() external {
        withdrawAll();
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateReward(address(0))
    {
        PICKLE.safeTransferFrom(DISTRIBUTION, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = PICKLE.balanceOf(address(this));
        require(rewardRate <= balance / DURATION, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        emit RewardAdded(reward);
    }

    function setMultipliers(uint256 _lock_max_multiplier) external onlyGov {
        require(
            _lock_max_multiplier >= uint256(1e18),
            "Multiplier must be greater than or equal to 1e18"
        );
        lock_max_multiplier = _lock_max_multiplier;
        emit LockedStakeMaxMultiplierUpdated(lock_max_multiplier);
    }

    function setMaxRewardsDuration(uint256 _lock_time_for_max_multiplier)
        external
        onlyGov
    {
        require(
            _lock_time_for_max_multiplier >= 86400,
            "Rewards duration too short"
        );
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Reward period incomplete"
        );
        lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
        emit MaxRewardsDurationUpdated(lock_time_for_max_multiplier);
    }

    function unlockStakes() external onlyGov {
        stakesUnlocked = !stakesUnlocked;
    }

    function unlockStakeForAccount(address account) external onlyGov {
        stakesUnlockedForAccount[account] = !stakesUnlockedForAccount[account];
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 secs,
        uint256 index
    );
    event Withdrawn(address indexed user, uint256 amount, uint256 index);
    event RewardPaid(address indexed user, uint256 reward);
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
    event MaxRewardsDurationUpdated(uint256 newDuration);
}

interface MasterChef {
    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256, uint256);
}

contract MasterDill {
    /// @notice EIP-20 token name for this token
    string public constant name = "Master DILL";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "mDILL";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 1e18;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor() public {
        balances[msg.sender] = 1e18;
        emit Transfer(address(0x0), msg.sender, 1e18);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        // if (spender != src && spenderAllowance != uint256(-1)) { // type(uint256).max
        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance -
                (
                    amount
                    // ,
                    // "transferFrom: exceeds spender allowance"
                );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");

        balances[src] =
            balances[src] -
            (
                amount
                // ,
                // "_transferTokens: exceeds balance"
            );
        balances[dst] += (
            amount
            // ,
            //  "_transferTokens: overflows"
        );
        emit Transfer(src, dst, amount);
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract GaugeProxyV2 is ProtocolGovernance, Initializable {
    using SafeERC20 for IERC20;

    MasterChef public constant MASTER =
        MasterChef(0xbD17B1ce622d73bD438b9E658acA5996dc394b0d);
    IERC20 public constant DILL =
        IERC20(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf);
    IERC20 public constant PICKLE =
        IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);

    IERC20 public TOKEN;

    uint256 public pid;

    address[] internal _tokens;

    // token => gauge
    mapping(address => address) public gauges;
    mapping(address => uint256) public gaugeWithNegativeWeight;

    uint256 public constant WEEK_SECONDS = 604800;
    // epoch time stamp
    uint256 public firstDistribution;
    uint256 public distributionId;
    uint256 public lastVotedPeriodId;

    mapping(address => uint256) public tokenLastVotedPeriodId; // token => last voted period id
    mapping(address => int256) public usedWeights; // msg.sender => total voting weight of user
    mapping(address => address[]) public tokenVote; // msg.sender => token
    mapping(address => mapping(address => int256)) public votes; // msg.sender => votes
    mapping(uint256 => mapping(address => int256)) public weights; // period id => token => weight
    mapping(uint256 => int256) public totalWeight; // period id => TotalWeight
    mapping(uint256 => mapping(uint256 => bool)) public distributed;
    mapping(uint256 => uint256) public periodForDistribute; // dist id => which period id votes to use

    struct delegateData {
        // delegated address
        address delegate;
        // previous delegated address if updated, else zero address
        address prevDelegate;
        // period id when delegate address was updated
        uint256 updatePeriodId;
        // endPeriod if defined. Else 0.
        uint256 endPeriod;
        // If no endPeriod
        bool indefinite;
        // Period => Boolean (if delegate address can vote in that period)
        mapping(uint256 => bool) blockDelegate;
    }

    mapping(address => delegateData) public delegations;

    function getCurrentPeriodId() public view returns (uint256) {
        return
            block.timestamp > firstDistribution
                ? ((block.timestamp - firstDistribution) / WEEK_SECONDS) + 1
                : 0;
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    function initialize(uint256 _firstDistribution) public initializer {
        TOKEN = IERC20(address(new MasterDill()));
        governance = msg.sender;
        firstDistribution = _firstDistribution;
        distributionId = 1;
        lastVotedPeriodId = 1;
        periodForDistribute[1] = 1;
    }

    // Reset votes to 0
    function reset() external {
        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        _reset(msg.sender, currentId);
    }

    // Reset votes to 0
    function _reset(address _owner, uint256 _currentId) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;
        require(_currentId > 0, "Voting not started");

        if (_currentId > lastVotedPeriodId) {
            totalWeight[_currentId] = totalWeight[lastVotedPeriodId];
            lastVotedPeriodId = _currentId;
        }

        for (uint256 i = 0; i < _tokenVoteCnt; i++) {
            address _token = _tokenVote[i];
            int256 _votes = votes[_owner][_token];

            if (_votes != 0) {
                totalWeight[_currentId] -= (_votes > 0 ? _votes : -_votes);

                if (_currentId > tokenLastVotedPeriodId[_token]) {
                    weights[_currentId][_token] = weights[
                        tokenLastVotedPeriodId[_token]
                    ][_token];

                    tokenLastVotedPeriodId[_token] = _currentId;
                }

                weights[_currentId][_token] -= _votes;
                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
        // Ensure distribute rewards are for current period
        periodForDistribute[_currentId] = _currentId;
    }

    // Adjusts _owner's votes according to latest _owner's DILL balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        int256[] memory _weights = new int256[](_tokenCnt);
        uint256 currentId = getCurrentPeriodId();

        int256 _prevUsedWeight = usedWeights[_owner];
        int256 _weight = int256(DILL.balanceOf(_owner));

        for (uint256 i = 0; i < _tokenCnt; i++) {
            int256 _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = (_prevWeight * (_weight)) / (_prevUsedWeight);
        }
        _vote(_owner, _tokenVote, _weights, currentId);
    }

    function _vote(
        address _owner,
        address[] memory _tokenVote,
        int256[] memory _weights,
        uint256 _currentId
    ) internal {
        _reset(_owner, _currentId);
        uint256 _tokenCnt = _tokenVote.length;
        int256 _weight = int256(DILL.balanceOf(_owner));
        int256 _totalVoteWeight = 0;
        int256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _totalVoteWeight += (_weights[i] > 0 ? _weights[i] : -_weights[i]);
        }

        for (uint256 i = 0; i < _tokenCnt; i++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            int256 _tokenWeight = (_weights[i] * _weight) / _totalVoteWeight;
            if (_gauge != address(0x0)) {
                if (_currentId > tokenLastVotedPeriodId[_token]) {
                    weights[_currentId][_token] = weights[
                        tokenLastVotedPeriodId[_token]
                    ][_token];

                    tokenLastVotedPeriodId[_token] = _currentId;
                }

                weights[_currentId][_token] += _tokenWeight;
                votes[_owner][_token] = _tokenWeight;
                tokenVote[_owner].push(_token);

                if (_tokenWeight < 0) _tokenWeight = -_tokenWeight;

                _usedWeight += _tokenWeight;
                totalWeight[_currentId] += _tokenWeight;
            }
        }
        usedWeights[_owner] = _usedWeight;
    }

    // Vote with DILL on a gauge
    function vote(address[] calldata _tokenVote, int256[] calldata _weights)
        external
    {
        require(
            _tokenVote.length == _weights.length,
            "GaugeProxy: token votes count does not match weights count"
        );
        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        _vote(msg.sender, _tokenVote, _weights, currentId);
        delegations[msg.sender].blockDelegate[currentId] = true;
    }

    function setVotingDelegate(
        address _delegateAddress,
        uint256 _periodsCount,
        bool _indefinite
    ) external {
        require(
            _delegateAddress != address(0),
            "GaugeProxyV2: cannot delegate zero address"
        );
        require(
            _delegateAddress != msg.sender,
            "GaugeProxyV2: delegate address cannot be delegating"
        );

        delegateData storage _delegate = delegations[msg.sender];

        uint256 currentPeriodId = getCurrentPeriodId();

        address currentDelegate = _delegate.delegate;
        _delegate.delegate = _delegateAddress;
        _delegate.prevDelegate = currentDelegate;
        _delegate.updatePeriodId = currentPeriodId;

        if (_indefinite == true) {
            _delegate.indefinite = true;
        } else if (_delegate.prevDelegate == address(0)) {
            _delegate.endPeriod = currentPeriodId + _periodsCount - 1;
        } else {
            _delegate.endPeriod = currentPeriodId + _periodsCount;
        }
    }

    function voteFor(
        address _owner,
        address[] calldata _tokenVote,
        int256[] calldata _weights
    ) external {
        require(
            _tokenVote.length == _weights.length,
            "GaugeProxy: token votes count does not match weights count"
        );

        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        delegateData storage _delegate = delegations[_owner];
        require(
            (_delegate.delegate == msg.sender &&
                currentId > _delegate.updatePeriodId) ||
                (_delegate.prevDelegate == msg.sender &&
                    currentId == _delegate.updatePeriodId) ||
                (_delegate.prevDelegate == address(0) &&
                    currentId == _delegate.updatePeriodId),
            "Sender not authorized"
        );
        require(
            _delegate.blockDelegate[currentId] == false,
            "Delegating address has already voted"
        );
        require(
            (_delegate.indefinite || currentId <= _delegate.endPeriod),
            "Delegating period expired"
        );

        _vote(_owner, _tokenVote, _weights, currentId);
    }

    // Add new token gauge
    function addGauge(address _token) external {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(new GaugeV2(_token, governance));
        _tokens.push(_token);
    }

    function delistGauge(address _token) external {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] != address(0x0), "!exists");

        uint256 currentId = getCurrentPeriodId();
        require(distributionId == currentId, "! all distributions completed");

        address _gauge = gauges[_token];

        require(gaugeWithNegativeWeight[_gauge] >= 5, "censors < 5");

        delete gauges[_token];

        uint256 tokensLength = _tokens.length;
        address[] memory newTokenArray = new address[](tokensLength - 1);

        uint256 j = 0;
        for (uint256 i = 0; i < tokensLength; i++) {
            if (_tokens[i] != _token) {
                newTokenArray[j] = _tokens[i];
                j++;
            }
        }

        _tokens = newTokenArray;
    }

    // Sets MasterChef PID
    function setPID(uint256 _pid) external {
        require(msg.sender == governance, "!gov");
        require(pid == 0, "pid has already been set");
        require(_pid > 0, "invalid pid");
        pid = _pid;
    }

    // Deposits mDILL into MasterChef
    function deposit() public {
        require(pid > 0, "pid not initialized");
        IERC20 _token = TOKEN;
        uint256 _balance = _token.balanceOf(address(this));
        _token.safeApprove(address(MASTER), 0);
        _token.safeApprove(address(MASTER), _balance);
        MASTER.deposit(pid, _balance);
    }

    // Fetches Pickle
    function collect() public {
        (uint256 _locked, ) = MASTER.userInfo(pid, address(this));
        MASTER.withdraw(pid, _locked);
        deposit();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function distribute(uint256 _start, uint256 _end) external {
        require(_start < _end, "GaugeProxyV2: bad _start");
        require(_end <= _tokens.length, "GaugeProxyV2: bad _end");
        require(
            msg.sender == governance,
            "GaugeProxyV2: only governance can distribute"
        );

        uint256 currentId = getCurrentPeriodId();
        require(
            distributionId < currentId,
            "GaugeProxyV2: all period distributions complete"
        );

        uint256 periodToUse = 0;
        if (periodForDistribute[distributionId] == 0) {
            // If period does not exist means no votes in this period
            // Use previous period's votes and update dist. period
            periodToUse = periodForDistribute[distributionId - 1];
            periodForDistribute[distributionId] = periodForDistribute[
                distributionId - 1
            ];
        } else {
            periodToUse = periodForDistribute[distributionId];
        }

        collect();
        int256 _balance = int256(PICKLE.balanceOf(address(this)));
        int256 _totalWeight = totalWeight[periodToUse];

        if (_balance > 0 && _totalWeight > 0) {
            for (uint256 i = _start; i < _end; i++) {
                if (distributed[distributionId][i]) {
                    continue;
                }
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                int256 _reward = (_balance * weights[periodToUse][_token]) /
                    _totalWeight;
                if (_reward > 0) {
                    PICKLE.safeApprove(_gauge, 0);
                    PICKLE.safeApprove(_gauge, uint256(_reward));
                    GaugeV2(_gauge).notifyRewardAmount(uint256(_reward));
                }

                if (_reward < 0) {
                    gaugeWithNegativeWeight[_gauge] += 1;
                }
                distributed[distributionId][i] = true;
            }
        }

        if (_tokens.length == _end) {
            distributionId += 1;
        }
    }
}
