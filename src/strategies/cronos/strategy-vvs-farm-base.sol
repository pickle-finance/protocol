// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/vvs-chef.sol";

abstract contract StrategyVVSFarmBase is StrategyBase {
    // Token addresses
    address public constant vvs = 0x2D03bECE6747ADC00E1a131BBA1469C15fD11e03;
    address public constant vvsChef =
        0xDccd6455AE04b03d785F12196B492b18129564bc;

    address public token0;
    address public token1;

    // How much VVS tokens to keep?
    uint256 public keepVVS = 1000;
    uint256 public constant keepVVSMax = 10000;

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
        sushiRouter = 0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae;
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IVvsChef(vvsChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IVvsChef(vvsChef).pendingVvs(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(vvsChef, 0);
            IERC20(want).safeApprove(vvsChef, _want);
            IVvsChef(vvsChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IVvsChef(vvsChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepVVS(uint256 _keepVVS) external {
        require(msg.sender == timelock, "!timelock");
        keepVVS = _keepVVS;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects VVS tokens
        IVvsChef(vvsChef).deposit(poolId, 0);
        uint256 _vvs = IERC20(vvs).balanceOf(address(this));

        if (_vvs > 0) {
            uint256 _keepVVS = _vvs.mul(keepVVS).div(keepVVSMax);
            IERC20(vvs).safeTransfer(
                IController(controller).treasury(),
                _keepVVS
            );
            _vvs = _vvs.sub(_keepVVS);
            uint256 toToken0 = _vvs.div(2);
            uint256 toToken1 = _vvs.sub(toToken0);

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
