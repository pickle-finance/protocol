// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../interfaces/beam-chef.sol";

abstract contract StrategyBeamFarmBase is StrategyBase {
    // Token addresses
    address public glint = 0xcd3B51D98478D53F4515A306bE565c6EebeF1D58;
    address public constant beamChef =
        0xC6ca172FC8BDB803c5e12731109744fb0200587b;

    address public token0;
    address public token1;

    // How much GLINT tokens to keep?
    uint256 public keepGLINT = 1000;
    uint256 public constant keepGLINTMax = 10000;

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
        // Beamswap router
        sushiRouter = 0x96b244391D98B62D19aE89b1A4dCcf0fc56970C7;
        poolId = _poolId;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = IBeamChef(beamChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        
        (, , , uint256[] amounts) =
         IBeamChef(beamChef).pendingTokens(poolId, address(this));
         return amounts[0];
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(beamChef, 0);
            IERC20(want).safeApprove(beamChef, _want);
            IBeamChef(beamChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBeamChef(beamChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepGLINT(uint256 _keepGLINT) external {
        require(msg.sender == timelock, "!timelock");
        keepGLINT = _keepGLINT;
    }

    // **** State Mutations ****

    function harvest() public override {
        // Collects GLINT tokens
        IBeamChef(beamChef).deposit(poolId, 0);
        uint256 _glint = IERC20(glint).balanceOf(address(this));

        if (_glint > 0) {
            uint256 _keepGLINT = _glint.mul(keepGLINT).div(keepGLINTMax);
            IERC20(glint).safeTransfer(
                IController(controller).treasury(),
                _keepGLINT
            );
            _glint = _glint.sub(_keepGLINT);
            uint256 toToken0 = _glint.div(2);
            uint256 toToken1 = _glint.sub(toToken0);

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
