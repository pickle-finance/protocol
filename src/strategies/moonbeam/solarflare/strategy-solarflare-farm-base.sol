// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../interfaces/flare-chef.sol";

abstract contract StrategyFlareFarmBase is StrategyBase {
    // Token addresses
    address public constant flare = 0xE3e43888fa7803cDC7BEA478aB327cF1A0dc11a7;
    address public constant flareChef =
        0x995da7dfB96B4dd1e2bd954bE384A1e66cBB4b8c;

    address public token0;
    address public token1;

    // How much FLARE tokens to keep?
    uint256 public keepFLARE = 1000;
    uint256 public constant keepFLAREMax = 10000;

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
        // Flareswap router
        sushiRouter = 0xd3B02Ff30c218c7f7756BA14bcA075Bf7C2C951e;
        poolId = _poolId;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = IFlareChef(flareChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IFlareChef(flareChef).pendingTokens(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(flareChef, 0);
            IERC20(want).safeApprove(flareChef, _want);
            IFlareChef(flareChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IFlareChef(flareChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepFLARE(uint256 _keepFLARE) external {
        require(msg.sender == timelock, "!timelock");
        keepFLARE = _keepFLARE;
    }

    // **** State Mutations ****

    function harvest() public override {
        // Collects FLARE tokens
        IFlareChef(flareChef).deposit(poolId, 0);
        uint256 _flare = IERC20(flare).balanceOf(address(this));

        if (_flare > 0) {
            uint256 _keepFLARE = _flare.mul(keepFLARE).div(keepFLAREMax);
            IERC20(flare).safeTransfer(
                IController(controller).treasury(),
                _keepFLARE
            );
            _flare = _flare.sub(_keepFLARE);
            uint256 toToken0 = _flare.div(2);
            uint256 toToken1 = _flare.sub(toToken0);

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
