// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IAnyswapBridger {
    function bridge(uint256 amount) external payable;
}

contract TestRootChainGaugeV2 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public PICKLE;

    // Constant for various precisions
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    //Reward addresses, rates, and symbols
    uint256 public rewardRate;

    // Time tracking
    uint256 public periodFinish = 0;
    uint256 public lastUpdateTime;
    IAnyswapBridger public anyswapBridger;

    /* ========== MODIFIERS ========== */

    modifier onlyDistribution() {
        require(
            msg.sender == DISTRIBUTION,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _anyswapBridger, address _pickleAddress) {
        PICKLE = IERC20(_pickleAddress);
        anyswapBridger = IAnyswapBridger(_anyswapBridger);

        DISTRIBUTION = msg.sender;
    }

    /* ========== VIEWS ========== */

    function getRewardForDuration()
        external
        view
        returns (uint256)
    {

        return rewardRate * DURATION;
    }

    function changeAnySwapBridger(address _anySwapBridger) external {
        require(_anySwapBridger != address(0), "cannot have zero address");
        anyswapBridger = IAnyswapBridger(_anySwapBridger);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 amount) external onlyDistribution {
        uint256 rewardRateUpdate = rewardRate;

        if (block.timestamp >= periodFinish) {
            rewardRateUpdate = amount / DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRateUpdate;
            rewardRateUpdate = (amount + leftover) / DURATION;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        PICKLE.safeTransferFrom(DISTRIBUTION, address(anyswapBridger), amount);
        uint256 balance = PICKLE.balanceOf(address(this));
        require(rewardRateUpdate <= balance / DURATION, "Provided reward too high");
        rewardRate = rewardRateUpdate;
        anyswapBridger.bridge(amount);
        emit RewardAdded(amount);
    }

    /* ========== EVENTS ========== */
    event RewardAdded(uint256 amount);
}