pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/rose-rewards.sol";

abstract contract StrategyRoseFarmStableBase is StrategyBase {
    address public rewards;
    address public padRouter = 0xBaE0d7DFcd03C90EBCe003C58332c1346A72836A;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;
    address public dai = 0xe3520349F477A5F6EB06107066048508498A291b;
    address public pad = 0x885f8CF6E45bdd3fdcDc644efdcd0AC93880c781;

    address public three_pool = 0xc90dB0d8713414d78523436dC347419164544A3f;

    address public token0;
    address public token1;

    // How much ROSE tokens to keep?
    uint256 public keepROSE = 1000;
    uint256 public constant keepROSEMax = 10000;

    // **** Getters ****
    constructor(
        address _rewards,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        rewards = _rewards;
        sushiRouter = padRouter;

        IERC20(dai).approve(three_pool, uint256(-1));
        IERC20(want).approve(rewards, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        return IRoseRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IRoseRewards(rewards).earned(address(this), rose);
    }

    // **** Setters ****

    function setKeepROSE(uint256 _keepROSE) external {
        require(msg.sender == timelock, "!timelock");
        keepROSE = _keepROSE;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IRoseRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IRoseRewards(rewards).withdraw(_amount);
        return _amount;
    }

    function harvest() public virtual override {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
    }

    // **** State Mutations ****
    function harvestOne() public virtual {
        // Collect ROSE tokens
        IRoseRewards(rewards).getReward();
        uint256 _rose = IERC20(rose).balanceOf(address(this));

        if (_rose > 0) {
            uint256 _keepROSE = _rose.mul(keepROSE).div(keepROSEMax);
            IERC20(rose).safeTransfer(
                IController(controller).treasury(),
                _keepROSE
            );
        }
    }

    function harvestTwo() public virtual {
        uint256 _rose = IERC20(rose).balanceOf(address(this));

        if (_rose > 0) {
            // Use Dai because most premium token in pool
            address[] memory route = new address[](3);
            route[0] = rose;
            route[1] = pad;
            route[2] = dai;

            _swapSushiswapWithPath(route, _rose);
        }
    }

    function harvestThree() public virtual {
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            uint256[3] memory liquidity;
            liquidity[0] = _dai;
            ICurveFi_3(three_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFour() public virtual {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
