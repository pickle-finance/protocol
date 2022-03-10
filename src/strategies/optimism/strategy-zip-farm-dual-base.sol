// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/zip-chef.sol";

import "./strategy-base.sol";
import "../../interfaces/netswap-chef.sol";

abstract contract StrategyZipFarmDualBase is StrategyBase {
    address public constant zip = 0xFA436399d0458Dbe8aB890c3441256E3E09022a8;
    address public constant zipChef =
        0x1e2F8e5f94f366eF5Dc041233c0738b1c1C2Cb0c;
    address public token0;
    address public token1;
    address public extraReward;

    // How much Reward tokens to keep?
    uint256 public keepREWARD = 420;
    uint256 public constant keepREWARDMax = 10000;

    mapping(address => address[]) public swapRoutes;

    uint256 public poolId;

    // **** Getters ****
    constructor(
        address _want,
        uint256 _poolId,
        address _extraReward,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        sushiRouter = 0xE6Df0BB08e5A97b40B21950a0A51b94c4DbA0Ff6;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;
        extraReward = _extraReward;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(zip).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(sushiRouter, uint256(-1));
        IERC20(extraReward).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IZipChef(zipChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IZipChef(zipChef).pendingReward(poolId, address(this));
    }

    // **** Setters ****

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
    }

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

    function harvest() public override {
        // Collects ZIP tokens
        IZipChef(zipChef).harvest(poolId, address(this));

        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        uint256 _zip = IERC20(zip).balanceOf(address(this));

        if (_extraReward == 0 && _zip == 0) return;

        // Swap ZIP to extra reward if part of pair
        if (extraReward == token0 || extraReward == token1) {
            if (swapRoutes[extraReward].length > 1 && _zip > 0)
                _swapSushiswapWithPath(swapRoutes[extraReward], _zip);

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
        // If extra reward not part of pair, swap to ZIP
        else {
            if (swapRoutes[zip].length > 1 && _extraReward > 0)
                _swapSushiswapWithPath(swapRoutes[zip], _extraReward);

            _zip = IERC20(zip).balanceOf(address(this));
            uint256 _keepZIP = _zip.mul(keepREWARD).div(keepREWARDMax);
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
