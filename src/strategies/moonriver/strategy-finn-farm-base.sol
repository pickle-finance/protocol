// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/finn-chef.sol";

abstract contract StrategyFinnFarmBase is StrategyBase {
    // Token addresses
    address public constant finn = 0x9A92B5EBf1F6F6f7d93696FCD44e5Cf75035A756;
    address public constant finnChef =
        0x1f4b7660b6AdC3943b5038e3426B33c1c0e343E6;

    address public token0;
    address public token1;

    // How much FINN tokens to keep?
    uint256 public keepFINN = 1000;
    uint256 public constant keepFINNMax = 10000;

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
        (uint256 amount, , , ) = IFinnChef(finnChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IFinnChef(finnChef).pendingFinn(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(finnChef, 0);
            IERC20(want).safeApprove(finnChef, _want);
            IFinnChef(finnChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IFinnChef(finnChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepFINN(uint256 _keepFINN) external {
        require(msg.sender == timelock, "!timelock");
        keepFINN = _keepFINN;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects FINN tokens
        IFinnChef(finnChef).deposit(poolId, 0);
        uint256 _finn = IERC20(finn).balanceOf(address(this));

        if (_finn > 0) {
            uint256 _keepFINN = _finn.mul(keepFINN).div(keepFINNMax);
            IERC20(finn).safeTransfer(
                IController(controller).treasury(),
                _keepFINN
            );
            _finn = _finn.sub(_keepFINN);
            uint256 toToken0 = _finn.div(2);
            uint256 toToken1 = _finn.sub(toToken0);

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
