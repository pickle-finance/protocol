// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/basket-chef.sol";

abstract contract StrategyBasketFarmBase is StrategyBase {
    // Token addresses
    address public constant basket = 0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb;
    address public constant masterChef = 0xDB9daa0a50B33e4fe9d0ac16a1Df1d335F96595e;

    // WETH/<token1> pair
    address public token1;

    // How much BASK tokens to keep?
    uint256 public keepBASK = 0;
    uint256 public constant keepBASKMax = 10000;

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
        IERC20(basket).safeApprove(sushiRouter, uint(-1));
        IERC20(weth).safeApprove(sushiRouter, uint(-1));
    }
    
    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount, ) = IBasketChef(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IBasketChef(masterChef).pendingBasket(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            IBasketChef(masterChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBasketChef(masterChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepBASK(uint256 _keepBASK) external {
        require(msg.sender == timelock, "!timelock");
        keepBASK = _keepBASK;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        IBasketChef(masterChef).deposit(poolId, 0);
        uint256 _bask = IERC20(basket).balanceOf(address(this));
        if (_bask > 0) {
            // 10% is locked up for future gov
            uint256 _keepBASK = _bask.mul(keepBASK).div(keepBASKMax);
            IERC20(basket).safeTransfer(
                IController(controller).treasury(),
                _keepBASK
            );
            _swapSushiswap(basket, weth, _bask.sub(_keepBASK));
        }

        // Swap half WETH for other asset
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/token1
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {

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

        // We want to get back Bask LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
