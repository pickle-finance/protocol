// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/crona-chef.sol";

abstract contract StrategyCronaFarmBase is StrategyBase {
    // Token addresses
    address public constant crona = 0xadbd1231fb360047525BEdF962581F3eee7b49fe;
    address public constant cronaChef =
        0x77ea4a4cF9F77A034E4291E8f457Af7772c2B254;

    address public token0;
    address public token1;

    // How much CRONA tokens to keep?
    uint256 public keepCRONA = 1000;
    uint256 public constant keepCRONAMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public uniswapRoutes;

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
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ICronaChef(cronaChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ICronaChef(cronaChef).pendingCrona(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cronaChef, 0);
            IERC20(want).safeApprove(cronaChef, _want);
            ICronaChef(cronaChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICronaChef(cronaChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepCRONA(uint256 _keepCRONA) external {
        require(msg.sender == timelock, "!timelock");
        keepCRONA = _keepCRONA;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects CRONA tokens
        ICronaChef(cronaChef).deposit(poolId, 0);
        uint256 _crona = IERC20(crona).balanceOf(address(this));

        if (_crona > 0) {
            uint256 _keepCRONA = _crona.mul(keepCRONA).div(keepCRONAMax);
            IERC20(crona).safeTransfer(
                IController(controller).treasury(),
                _keepCRONA
            );
            _crona = _crona.sub(_keepCRONA);
            uint256 toToken0 = _crona.div(2);
            uint256 toToken1 = _crona.sub(toToken0);

            if (uniswapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token0], toToken0);
            }
            if (uniswapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token1], toToken1);
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

        _distributePerformanceFeesAndDeposit();
    }
}
