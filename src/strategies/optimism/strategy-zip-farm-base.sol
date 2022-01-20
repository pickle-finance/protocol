// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/zip-chef.sol";

abstract contract StrategyZipFarmBase is StrategyBase {
    // Token addresses
    address public constant zip = 0xFA436399d0458Dbe8aB890c3441256E3E09022a8;
    address public constant zipChef =
        0x1e2F8e5f94f366eF5Dc041233c0738b1c1C2Cb0c;

    address public token0;
    address public token1;

    // How much ZIP tokens to keep?
    uint256 public keepZIP = 1000;
    uint256 public constant keepZIPMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _lp,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        // Zipswap router
        sushiRouter = 0xE6Df0BB08e5A97b40B21950a0A51b94c4DbA0Ff6;
        poolId = _poolId;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();

        IERC20(token0).safeApprove(sushiRouter, uint256(-1));
        IERC20(token1).safeApprove(sushiRouter, uint256(-1));
        IERC20(zip).safeApprove(sushiRouter, uint256(-1));
        IERC20(want).safeApprove(zipChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IZipChef(zipChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IZipChef(zipChef).pendingReward(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint128 _want = uint128(IERC20(want).balanceOf(address(this)));
        if (_want > 0) {
            IZipChef(zipChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IZipChef(zipChef).withdraw(poolId, uint128(_amount), address(this));
        return _amount;
    }

    function setKeepZIP(uint256 _keepZIP) external {
        require(msg.sender == timelock, "!timelock");
        keepZIP = _keepZIP;
    }

    // **** State Mutations ****

    function harvest() public override {
        // Collects ZIP tokens
        IZipChef(zipChef).harvest(poolId, address(this));
        uint256 _zip = IERC20(zip).balanceOf(address(this));

        if (_zip > 0) {
            uint256 _keepZIP = _zip.mul(keepZIP).div(keepZIPMax);
            IERC20(zip).safeTransfer(
                IController(controller).treasury(),
                _keepZIP
            );
            _zip = _zip.sub(_keepZIP);
            uint256 toToken0 = _zip.div(2);
            uint256 toToken1 = _zip.sub(toToken0);

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
