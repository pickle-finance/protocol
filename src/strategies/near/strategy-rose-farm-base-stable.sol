pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/rose-rewards.sol";

abstract contract StrategyRoseFarmStableBase is StrategyBase {
    address public rewards;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

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

        IERC20(usdc).approve(three_pool, uint256(-1));
        IERC20(usdt).approve(three_pool, uint256(-1));
        IERC20(want).approve(rewards, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        return IRoseRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IRoseRewards(rewards).earned(address(this), rose);
    }

    function getMostPremium() public view returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(three_pool).balances(0); // DAI
        balances[1] = ICurveFi_3(three_pool).balances(1); // USDC
        balances[2] = ICurveFi_3(three_pool).balances(2); // USDT

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (usdc, 1);
        }
        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }
        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (usdc, 1);
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

        (address to, uint256 toIndex) = getMostPremium();

        if (_rose > 0) {
            // Use Dai because most premium token in pool
            address[] memory route = new address[](3);
            route[0] = rose;
            route[1] = near;
            route[2] = to;

            _swapSushiswapWithPath(route, _rose);

            uint256 _to = IERC20(to).balanceOf(address(this));
            if (_to > 0) {
                uint256[3] memory liquidity;
                liquidity[toIndex] = _to;
                ICurveFi_3(three_pool).add_liquidity(liquidity, 0);
            }
        }
    }

    function harvestThree() public virtual {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
