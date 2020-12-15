// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/sushi-chef.sol";

abstract contract StrategySushiFarmBase is StrategyBase {
    // Token addresses
    address public constant sushi = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address public constant masterChef = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    // WETH/<token1> pair
    address public token1;

    // How much SUSHI tokens to keep?
    uint256 public keepSUSHI = 0;
    uint256 public constant keepSUSHIMax = 10000;

    uint256 public poolId;

    constructor(
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        poolId = _poolId;
        token1 = _token1;
    }
    
    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount, ) = ISushiChef(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ISushiChef(masterChef).pendingSushi(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            ISushiChef(masterChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiChef(masterChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepSUSHI(uint256 _keepSUSHI) external {
        require(msg.sender == timelock, "!timelock");
        keepSUSHI = _keepSUSHI;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        ISushiChef(masterChef).deposit(poolId, 0);
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            // 10% is locked up for future gov
            uint256 _keepSUSHI = _sushi.mul(keepSUSHI).div(keepSUSHIMax);
            IERC20(sushi).safeTransfer(
                IController(controller).treasury(),
                _keepSUSHI
            );
            _swapSushiswap(sushi, weth, _sushi.sub(_keepSUSHI));
        }

        // Swap half WETH for DAI
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/DAI
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back SUSHI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
