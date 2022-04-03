// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-nearpad.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyNearPadFarmBase is StrategyBase {
    // Token addresses
    address public constant pad = 0x885f8CF6E45bdd3fdcDc644efdcd0AC93880c781;
    address public constant miniChef =
        0x2aeF68F92cfBAFA4b542F60044c7596e65612D20;
    address public constant padRouter =
        0xBaE0d7DFcd03C90EBCe003C58332c1346A72836A;

    // How much PAD tokens to keep?
    uint256 public keepPAD = 1000;
    uint256 public constant keepPADMax = 10000;

    // WETH/<token1> pair
    address public token0;
    address public token1;
    address rewardToken;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

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
        sushiRouter = padRouter;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(pad).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefNearPad(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingPad = IMiniChefNearPad(miniChef).pendingPad(
            poolId,
            address(this)
        );

        return _pendingPad;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChefNearPad(miniChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefNearPad(miniChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepPAD(uint256 _keepPAD) external {
        require(msg.sender == timelock, "!timelock");
        keepPAD = _keepPAD;
    }

    function harvest() public override {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
        harvestFive();
    }

    function harvestOne() public {
        // Collects TRI tokens
        IMiniChefNearPad(miniChef).deposit(poolId, 0);
        uint256 _pad = IERC20(pad).balanceOf(address(this));
        uint256 _keepPAD = _pad.mul(keepPAD).div(keepPADMax);

        IERC20(pad).safeTransfer(IController(controller).treasury(), _keepPAD);
    }

    function harvestTwo() public {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        uint256 _pad = IERC20(pad).balanceOf(address(this));
        if (_pad > 0) {
            uint256 toToken0 = _pad.div(2);

            if (swapRoutes[token0].length > 1) {
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    toToken0,
                    0,
                    swapRoutes[token0],
                    address(this),
                    now + 60
                );
            }
        }
    }

    function harvestThree() public {
        uint256 _pad = IERC20(pad).balanceOf(address(this));
        if (_pad > 0) {
            if (swapRoutes[token1].length > 1) {
                uint256 swapAmount = swapRoutes[token0].length > 1
                    ? _pad
                    : _pad.div(2);
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    swapAmount, // Swap the remainder of PAD
                    0,
                    swapRoutes[token1],
                    address(this),
                    now + 60
                );
            }
        }
    }

    function harvestFour() public {
        // Adds in liquidity for token0/token1
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

    function harvestFive() public {
        // We want to get back PAD LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
