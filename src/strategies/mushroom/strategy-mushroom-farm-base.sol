// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/shroom-chef.sol";

abstract contract StrategyMushroomFarmBase is StrategyBase {
    // Token addresses
    address public constant mushroom = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant shroomChef = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    // underlying token
    address public token1;

    // How much MM tokens to keep?
    uint256 public keepMM = 0;
    uint256 public constant keepMMMax = 10000;

    uint256 public poolId;

    constructor(
        address _token1,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _token1,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        poolId = _poolId;
        token1 = _token1;
        IERC20(mushroom).safeApprove(sushiRouter, uint(-1));
        IERC20(weth).safeApprove(sushiRouter, uint(-1));
    }
 
    
    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount, ) = IShroomChef(shroomChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IShroomChef(shroomChef).pendingMM(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(shroomChef, 0);
            IERC20(want).safeApprove(shroomChef, _want);
            IShroomChef(shroomChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IShroomChef(shroomChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepMM(uint256 _keepMM) external {
        require(msg.sender == timelock, "!timelock");
        keepMM = _keepMM;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects MM tokens
        IShroomChef(shroomChef).deposit(poolId, 0);
        uint256 _mm = IERC20(mushroom).balanceOf(address(this));
        if (_mm > 0) {
            // 10% is locked up for future gov
            uint256 _keepMM = _mm.mul(keepMM).div(keepMMMax);
            IERC20(mushroom).safeTransfer(
                IController(controller).treasury(),
                _keepMM
            );
            _swapSushiswap(mushroom, weth, _mm.sub(_keepMM));
        }

        // Swap WETH for token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapSushiswap(weth, token1, _weth);
        }

        // Donates DUST
        IERC20(weth).transfer(
            IController(controller).treasury(),
            IERC20(weth).balanceOf(address(this))
        );
        IERC20(token1).safeTransfer(
            IController(controller).treasury(),
            IERC20(token1).balanceOf(address(this))
        );
        

        // We want to get back tokens
        _distributePerformanceFeesAndDeposit();
    }
}
