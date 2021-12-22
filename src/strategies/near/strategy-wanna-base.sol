// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-wanna.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyWannaFarmBase is StrategyBase {
    // Token addresses
    address public constant wanna = 0x7faA64Faf54750a2E3eE621166635fEAF406Ab22;
    address public constant miniChef =
        0x2B2e72C232685fC4D350Eaa92f39f6f8AD2e1593;
    address public constant wannaRouter =
        0xa3a1eF5Ae6561572023363862e238aFA84C72ef5;

    // How much WANNA tokens to keep?
    uint256 public keepWANNA = 1000;
    uint256 public constant keepWANNAMax = 10000;

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
        sushiRouter = wannaRouter;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(wanna).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefWanna(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingWanna = IMiniChefWanna(miniChef).pendingWanna(
            poolId,
            address(this)
        );

        return _pendingWanna;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChefWanna(miniChef).deposit(poolId, _want, address(0));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefWanna(miniChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepWANNA(uint256 _keepWANNA) external {
        require(msg.sender == timelock, "!timelock");
        keepWANNA = _keepWANNA;
    }

    function harvest() public override onlyBenevolent {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
        harvestFive();
    }

    function harvestOne() public onlyBenevolent {
        // Collects TRI tokens
        IMiniChefWanna(miniChef).deposit(poolId, 0, address(0));
        uint256 _wanna = IERC20(wanna).balanceOf(address(this));
        uint256 _keepWANNA = _wanna.mul(keepWANNA).div(keepWANNAMax);

        IERC20(wanna).safeTransfer(
            IController(controller).treasury(),
            _keepWANNA
        );
    }

    function harvestTwo() public onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        uint256 _wanna = IERC20(wanna).balanceOf(address(this));
        if (_wanna > 0) {
            uint256 toToken0 = _wanna.div(2);

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

    function harvestThree() public onlyBenevolent {
        uint256 _wanna = IERC20(wanna).balanceOf(address(this));
        if (_wanna > 0) {
            if (swapRoutes[token1].length > 1) {
                // only swap half if token0 is WANNA
                uint256 swapAmount = swapRoutes[token0].length > 1
                    ? _wanna
                    : _wanna.div(2);
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    swapAmount, // Swap the remainder of WANNA
                    0,
                    swapRoutes[token1],
                    address(this),
                    now + 60
                );
            }
        }
    }

    function harvestFour() public onlyBenevolent {
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

    function harvestFive() public onlyBenevolent {
        // We want to get back WANNA LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
