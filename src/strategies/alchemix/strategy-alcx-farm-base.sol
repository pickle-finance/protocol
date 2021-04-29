// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/alcx-farm.sol";

abstract contract StrategyAlcxFarmBase is StrategyBase {
    // Token addresses
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
    address public constant stakingPool = 0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa;

    // How much ALCX tokens to keep?
    uint256 public keepAlcx = 0;
    uint256 public constant keepAlcxMax = 10000;

    uint256 public poolId;

    constructor(
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
    }
    

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IStakingPools(stakingPool).getStakeTotalDeposited(address(this), poolId);
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalUnclaimed(address(this), poolId);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingPool, 0);
            IERC20(want).safeApprove(stakingPool, _want);
            IStakingPools(stakingPool).deposit(poolId, _want);
        }
    }


    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStakingPools(stakingPool).withdraw(poolId, _amount);
        return _amount;
    }
    // **** Setters ****

    function setKeepAlcx(uint256 _keepAlcx) external {
        require(msg.sender == timelock, "!timelock");
        keepAlcx = _keepAlcx;
    }
    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects ALCX tokens
        IStakingPools(stakingPool).claim(poolId);
        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            // 10% is locked up for future gov
            uint256 _keepAlcx = _alcx.mul(keepAlcx).div(keepAlcxMax);
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                _keepAlcx
            );
            uint256 _amount = (_alcx.sub(_keepAlcx)).div(2);
            
            if (_amount > 0) {
                IERC20(alcx).safeApprove(sushiRouter, 0);
                IERC20(alcx).safeApprove(sushiRouter, _amount);                
                _swapSushiswap(alcx, weth, _amount);
            }
        }

        // Adds in liquidity for WETH/ALCX
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        
        _alcx = IERC20(alcx).balanceOf(address(this));

        if (_weth > 0 && _alcx > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(alcx).safeApprove(sushiRouter, 0);
            IERC20(alcx).safeApprove(sushiRouter, _alcx);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                alcx,
                _weth,
                _alcx,
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
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                IERC20(alcx).balanceOf(address(this))
            );
        }
        
        _distributePerformanceFeesAndDeposit();
    }
}
