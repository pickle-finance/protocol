// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-wanna.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyWannaFarmBaseV2 is StrategyBase {
    // Token addresses
    address public constant wanna = 0x7faA64Faf54750a2E3eE621166635fEAF406Ab22;
    address public constant miniChef =
        0xC574bf5Dd3635Bf839D737CfB214993521D57d32;
    address public constant wannaRouter =
        0xa3a1eF5Ae6561572023363862e238aFA84C72ef5;

    // How much REWARD tokens to keep?
    uint256 public keepREWARD = 1000;
    uint256 public constant keepREWARDMax = 10000;

    // WETH/<token1> pair
    address public token0;
    address public token1;
    address public extraReward;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _extraReward,
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
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
        sushiRouter = wannaRouter;
        extraReward = _extraReward;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(wanna).approve(sushiRouter, uint256(-1));
        IERC20(extraReward).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefWanna(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingWanna = IMiniChefWanna(miniChef).pendingWanna(
            poolId,
            address(this)
        );
        uint256 _pendingExtraReward = IMiniChefWanna(miniChef).pendingBonus(
            poolId,
            address(this)
        );

        return (_pendingWanna, _pendingExtraReward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(miniChef, uint256(-1));
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

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
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
        uint256 _keepREWARD = _wanna.mul(keepREWARD).div(keepREWARDMax);

        IERC20(wanna).safeTransfer(
            IController(controller).treasury(),
            _keepREWARD
        );
    }

    function harvestTwo() public virtual onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        uint256 _wanna = IERC20(wanna).balanceOf(address(this));

        if (extraReward == token0 || extraReward == token1) {
            if (swapRoutes[extraReward].length > 1 && _wanna > 0)
                _swapSushiswapWithPath(swapRoutes[extraReward], _wanna);

            _extraReward = IERC20(extraReward).balanceOf(address(this));
            uint256 _keepReward = _extraReward.mul(keepREWARD).div(
                keepREWARDMax
            );
            IERC20(extraReward).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _extraReward = IERC20(extraReward).balanceOf(address(this));
            address toToken = extraReward == token0 ? token1 : token0;

            if (swapRoutes[toToken].length > 1 && _extraReward > 0)
                _swapSushiswapWithPath(
                    swapRoutes[toToken],
                    _extraReward.div(2)
                );
        }
        // If extra reward not part of pair, swap to TRI
        else {
            if (swapRoutes[wanna].length > 1 && _extraReward > 0)
                _swapSushiswapWithPath(swapRoutes[wanna], _extraReward);

            _wanna = IERC20(wanna).balanceOf(address(this));
            uint256 _keepReward = _wanna.mul(keepREWARD).div(keepREWARDMax);
            IERC20(wanna).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _wanna = _wanna.sub(_keepReward);
            uint256 toToken0 = _wanna.div(2);
            uint256 toToken1 = _wanna.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token1], toToken1);
            }
        }
    }

    function harvestThree() public virtual onlyBenevolent {
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
