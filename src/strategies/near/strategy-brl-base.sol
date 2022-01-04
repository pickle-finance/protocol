// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/masterchef-brl.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyBrlFarmBase is StrategyBase {
    // Token addresses
    address public constant brl = 0x12c87331f086c3C926248f964f8702C0842Fd77F;
    address public constant miniChef =
        0x35CC71888DBb9FfB777337324a4A60fdBAA19DDE;
    address public constant brlRouter =
        0xA1B1742e9c32C7cAa9726d8204bD5715e3419861;

    // How much BRL tokens to keep?
    uint256 public keepBRL = 1000;
    uint256 public constant keepBRLMax = 10000;

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
        sushiRouter = brlRouter;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(brl).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefBrl(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingBrl = IMiniChefBrl(miniChef).pendingBRL(
            poolId,
            address(this)
        );

        return _pendingBrl;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChefBrl(miniChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefBrl(miniChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepBRL(uint256 _keepBRL) external {
        require(msg.sender == timelock, "!timelock");
        keepBRL = _keepBRL;
    }

    function harvest() public override onlyBenevolent {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
        harvestFive();
    }

    function harvestOne() public onlyBenevolent {
        // Collects BRL tokens
        IMiniChefBrl(miniChef).deposit(poolId, 0);
        uint256 _brl = IERC20(brl).balanceOf(address(this));
        uint256 _keepBRL = _brl.mul(keepBRL).div(keepBRLMax);

        IERC20(brl).safeTransfer(IController(controller).treasury(), _keepBRL);
    }

    function harvestTwo() public onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        uint256 _brl = IERC20(brl).balanceOf(address(this));
        if (_brl > 0) {
            uint256 toToken0 = _brl.div(2);

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
        uint256 _brl = IERC20(brl).balanceOf(address(this));
        if (_brl > 0) {
            if (swapRoutes[token1].length > 1) {
                // only swap half if token0 is BRL
                uint256 swapAmount = swapRoutes[token0].length > 1
                    ? _brl
                    : _brl.div(2);
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    swapAmount, // Swap the remainder of BRL
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
        // We want to get back BRL LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
