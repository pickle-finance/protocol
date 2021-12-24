pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/rose-rewards.sol";

abstract contract StrategyRoseFarmLPBase is StrategyBase {
    address public rewards;
    address public padRouter = 0xBaE0d7DFcd03C90EBCe003C58332c1346A72836A;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;
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
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
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

    function harvest() public override {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
    }

    // **** State Mutations ****
    function harvestOne() public {
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

    function harvestTwo() public {
        uint256 _rose = IERC20(rose).balanceOf(address(this));

        if (_rose > 0) {
            address[] memory route = new address[](2);
            if (token0 == rose) {
                route[0] = token0;
                route[1] = token1;
            } else {
                route[0] = token1;
                route[1] = token0;
            }

            _swapSushiswapWithPath(route, _rose.div(2));
        }
    }

    function harvestThree() public {
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function harvestFour() public {
        // We want to get back PAD LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
