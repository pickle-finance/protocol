// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/solar-chef.sol";

abstract contract StrategySolarFarmBase is StrategyBase {
    // Token addresses
    address public constant solar = 0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B;
    address public constant solarChef =
        0xf03b75831397D4695a6b9dDdEEA0E578faa30907;

    address public token0;
    address public token1;

    // How much SOLAR tokens to keep?
    uint256 public keepSOLAR = 1000;
    uint256 public constant keepSOLARMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public uniswapRoutes;

    constructor(
        address _token0,
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = ISolarChef(solarChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ISolarChef(solarChef).pendingSolar(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(solarChef, 0);
            IERC20(want).safeApprove(solarChef, _want);
            ISolarChef(solarChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISolarChef(solarChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepSOLAR(uint256 _keepSOLAR) external {
        require(msg.sender == timelock, "!timelock");
        keepSOLAR = _keepSOLAR;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects SOLAR tokens
        ISolarChef(solarChef).deposit(poolId, 0);
        uint256 _solar = IERC20(solar).balanceOf(address(this));

        if (_solar > 0) {
            uint256 _keepSOLAR = _solar.mul(keepSOLAR).div(keepSOLARMax);
            IERC20(solar).safeTransfer(
                IController(controller).treasury(),
                _keepSOLAR
            );
            _solar = _solar.sub(_keepSOLAR);
            uint256 toToken0 = _solar.div(2);
            uint256 toToken1 = _solar.sub(toToken0);

            if (uniswapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token0], toToken0);
            }
            if (uniswapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token1], toToken1);
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

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

        _distributePerformanceFeesAndDeposit();
    }
}
