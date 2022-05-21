// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/stella-chef.sol";
import "../../interfaces/stella-rewarder.sol";
import "../../interfaces/weth.sol";

abstract contract StrategyStellaFarmBaseV2 is StrategyBase {
    // Token addresses
    address public constant stella = 0x0E358838ce72d5e61E0018a2ffaC4bEC5F4c88d2;
    address public constant stellaChef = 0xF3a5454496E26ac57da879bf3285Fa85DEBF0388;
    address public constant stellaRouter = 0xd0A01ec574D1fC6652eDF79cb2F880fd47D34Ab1;
    address public rewarder;

    address public token0;
    address public token1;

    // How much STELLA tokens to keep?
    uint256 public keepREWARD = 1000;
    uint256 public constant keepREWARDMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _lp,
        uint256 _poolId,
        address _rewarder,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
        rewarder = _rewarder;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();

        IERC20(token0).approve(stellaRouter, uint256(-1));
        IERC20(token1).approve(stellaRouter, uint256(-1));
        IERC20(stella).approve(stellaRouter, uint256(-1));
        IERC20(glmr).approve(stellaRouter, uint256(-1));
        IERC20(want).approve(stellaChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = IStellaChef(stellaChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 PendingStella = IStellaChef(stellaChef).pendingStella(poolId, address(this));
        uint256 PendingGlmr = IStellaRewarder(rewarder).pendingTokens(poolId, address(this));

        return (PendingStella, PendingGlmr);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IStellaChef(stellaChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStellaChef(stellaChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepSTELLA(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
    }

    // **** State Mutations ****

    function harvest() public override {
        // Collects STELLA tokens
        IStellaChef(stellaChef).deposit(poolId, 0);

        uint256 _nakedGlmr = address(this).balance;
        WETH(glmr).deposit{value: _nakedGlmr}();

        uint256 _stella = IERC20(stella).balanceOf(address(this));

        if (_stella > 0) {
            if (swapRoutes[glmr].length > 1) {
                _swap(stellaRouter, swapRoutes[glmr], _stella);
            }
            uint256 _glmr = IERC20(glmr).balanceOf(address(this));
            uint256 _keepReward = _glmr.mul(keepREWARD).div(keepREWARDMax);
            IERC20(glmr).safeTransfer(IController(controller).treasury(), _keepReward);

            _glmr = IERC20(glmr).balanceOf(address(this));
            if (glmr == token0 || glmr == token1) {
                address toToken = glmr == token0 ? token1 : token0;

                if (swapRoutes[toToken].length > 1 && _glmr > 0) {
                    _swap(stellaRouter, swapRoutes[toToken], _glmr.div(2));
                }
            } else {
                uint256 toToken0 = _glmr.div(2);
                uint256 toToken1 = _glmr.sub(toToken0);

                if (swapRoutes[token0].length > 1) {
                    _swap(stellaRouter, swapRoutes[token0], toToken0);
                }
                if (swapRoutes[token1].length > 1) {
                    _swap(stellaRouter, swapRoutes[token1], toToken1);
                }
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(stellaRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).safeTransfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        _distributePerformanceFeesAndDeposit();
    }
}
