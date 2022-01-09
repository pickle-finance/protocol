// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-nettswap.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyNettSwapFarmBase is StrategyBase {
    // Token addresses
    address public constant nett = 0x90fE084F877C65e1b577c7b2eA64B8D8dd1AB278;
    address public constant miniChef =
        0x9d1dbB49b2744A1555EDbF1708D64dC71B0CB052;
    address public constant nettRouter =
        0x1E876cCe41B7b844FDe09E38Fa1cf00f213bFf56;

    // How much NETT tokens to keep?
    uint256 public keepNETT = 1000;
    uint256 public constant keepNETTMax = 10000;

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
        sushiRouter = nettRouter;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(nett).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefNettSwap(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingNett = IMiniChefNettSwap(miniChef).pendingNett(
            poolId,
            address(this)
        );

        return _pendingNett;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChefNettSwap(miniChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefNettSwap(miniChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepNETT(uint256 _keepNETT) external {
        require(msg.sender == timelock, "!timelock");
        keepNETT = _keepNETT;
    }

    function harvest() public override {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
        harvestFive();
    }

    function harvestOne() public {
        // Collects NETT tokens
        IMiniChefNettSwap(miniChef).deposit(poolId, 0);
        uint256 _nett = IERC20(nett).balanceOf(address(this));
        uint256 _keepNETT = _nett.mul(keepNETT).div(keepNETTMax);

        IERC20(nett).safeTransfer(
            IController(controller).treasury(),
            _keepNETT
        );
    }

    function harvestTwo() public {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        uint256 _nett = IERC20(nett).balanceOf(address(this));
        if (_nett > 0) {
            uint256 toToken0 = _nett.div(2);

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
        uint256 _nett = IERC20(nett).balanceOf(address(this));
        if (_nett > 0) {
            if (swapRoutes[token1].length > 1) {
                uint256 swapAmount = swapRoutes[token0].length > 1
                    ? _nett
                    : _nett.div(2);
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    swapAmount, // Swap the remainder of NETT
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
        // We want to get back NETT LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
