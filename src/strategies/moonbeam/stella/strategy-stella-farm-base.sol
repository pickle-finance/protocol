// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../interfaces/stella-chef.sol";

abstract contract StrategyStellaFarmBase is StrategyBase {
    // Token addresses
    address public constant stella = 0x0E358838ce72d5e61E0018a2ffaC4bEC5F4c88d2;
    address public constant stellaChef = 0xEDFB330F5FA216C9D2039B99C8cE9dA85Ea91c1E;

    address public token0;
    address public token1;

    // How much STELLA tokens to keep?
    uint256 public keepSTELLA = 1000;
    uint256 public constant keepSTELLAMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _lp,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        // Stellaswap router
        sushiRouter = 0xd0A01ec574D1fC6652eDF79cb2F880fd47D34Ab1;
        poolId = _poolId;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = IStellaChef(stellaChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IStellaChef(stellaChef).pendingStella(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stellaChef, 0);
            IERC20(want).safeApprove(stellaChef, _want);
            IStellaChef(stellaChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStellaChef(stellaChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepSTELLA(uint256 _keepSTELLA) external {
        require(msg.sender == timelock, "!timelock");
        keepSTELLA = _keepSTELLA;
    }

    // **** State Mutations ****

    function harvest() public override {
        // Collects STELLA tokens
        IStellaChef(stellaChef).deposit(poolId, 0);
        uint256 _stella = IERC20(stella).balanceOf(address(this));

        if (_stella > 0) {
            uint256 _keepSTELLA = _stella.mul(keepSTELLA).div(keepSTELLAMax);
            IERC20(stella).safeTransfer(IController(controller).treasury(), _keepSTELLA);
            _stella = _stella.sub(_keepSTELLA);
            uint256 toToken0 = _stella.div(2);
            uint256 toToken1 = _stella.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token1], toToken1);
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).safeTransfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        _distributePerformanceFeesAndDeposit();
    }
}
