// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/spiritswap.sol";


abstract contract StrategySpiritBase is StrategyBase {
    address public gaugeProxy = 0x420b17f69618610DE18caCd1499460EFb29e1d8f;
    address public spirit = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    address public gauge;
    address public token0;
    address public token1;
    address public pairRouter;

    mapping(address => address[]) public swapRoutes;

    // How much SPIRIT tokens to keep
    uint256 public keepSPIRIT = 420;
    uint256 public keepSPIRITMax = 10000;

    constructor(
        address _want,
        address _pairRouter,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        gauge = ISpiritGaugeProxy(gaugeProxy).getGauge(_want);
        sushiRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52; // Spiritswap router
        pairRouter = _pairRouter;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();

        IERC20(want).approve(gauge, uint256(-1));
        IERC20(spirit).approve(sushiRouter, uint256(-1));
        IERC20(token0).approve(pairRouter, uint256(-1));
        IERC20(token1).approve(pairRouter, uint256(-1));
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return ISpiritGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return ISpiritGauge(gauge).earned(address(this));
    }

    // **** Setters ****

    function setKeepSPIRIT(uint256 _keepSPIRIT) external {
        require(msg.sender == timelock, "!timelock");
        keepSPIRIT = _keepSPIRIT;
    }

    // **** State Mutation functions ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ISpiritGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISpiritGauge(gauge).withdraw(_amount);
        return _amount;
    }

    function _harvestRewards() internal returns (uint256) {
        // Collects SPIRIT tokens
        ISpiritGauge(gauge).getReward();
        uint256 _spirit = IERC20(spirit).balanceOf(address(this));

        if (_spirit > 0) {
            uint256 _keepSPIRIT = _spirit.mul(keepSPIRIT).div(keepSPIRITMax);

            // Send performance fees to treasury
            IERC20(spirit).safeTransfer(
                IController(controller).treasury(),
                _keepSPIRIT
            );

            return _spirit.sub(_keepSPIRIT);
        }

        return 0;
    }

    function harvest() public virtual override {
        uint256 _spirit = _harvestRewards();

        if (_spirit == 0) return;

        _swapSushiswap(spirit, wftm, _spirit);

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[1] = wftm;

        if (token0 != wftm && _token0 > 0) {
            path[0] = token0;
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                _token0,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            );
        }

        if (token1 != wftm && _token1 > 0) {
            path[0] = token1;
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                _token1,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            );
        }

        uint256 _wftm = IERC20(wftm).balanceOf(address(this));

        uint256 toToken0 = _wftm.div(2);
        uint256 toToken1 = _wftm.sub(toToken0);

        if (swapRoutes[token0].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken0,
                0,
                swapRoutes[token0],
                address(this),
                block.timestamp.add(60)
            );
        }
        if (swapRoutes[token1].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken1,
                0,
                swapRoutes[token1],
                address(this),
                block.timestamp.add(60)
            );
        }


        // Adds in liquidity for token0/token1
        _token0 = IERC20(token0).balanceOf(address(this));
        _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(pairRouter).addLiquidity(
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
