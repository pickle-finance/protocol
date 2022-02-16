pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/lqdr-chef.sol";

abstract contract StrategyLqdrFarmLPBase is StrategyBase {
    address public lqdr = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    address public masterchef = 0x5CEE2988184afE3CD807e0178B394259E8cdC56C;
    address public token0;
    address public token1;

    // How much LQDR tokens to keep?
    uint256 public keepLQDR = 1000;
    uint256 public constant keepLQDRMax = 10000;

    mapping(address => address[]) public swapRoutes;
    address public pairRouter;

    uint256 public poolId;

    // **** Getters ****
    constructor(
        address _want,
        uint256 _poolId,
        address _pairRouter,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        // Spiritswap router for LQDR liquidity
        sushiRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
        pairRouter =  _pairRouter;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;

        IERC20(token0).approve(pairRouter, uint256(-1));
        IERC20(token1).approve(pairRouter, uint256(-1));
        IERC20(wftm).approve(pairRouter, uint256(-1));
        IERC20(lqdr).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ILqdrChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 pendingLQDR = ILqdrChef(masterchef).pendingLqdr(
            poolId,
            address(this)
        );
        return pendingLQDR;
    }

    // **** Setters ****

    function setKeepLQDR(uint256 _keepLQDR) external {
        require(msg.sender == timelock, "!timelock");
        keepLQDR = _keepLQDR;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            ILqdrChef(masterchef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILqdrChef(masterchef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    function harvest() public override {
        ILqdrChef(masterchef).deposit(poolId, 0, address(this));
        uint256 _lqdr = IERC20(lqdr).balanceOf(address(this));

        if (_lqdr > 0) {
            uint256 _keepLQDR = _lqdr.mul(keepLQDR).div(keepLQDRMax);
            IERC20(lqdr).safeTransfer(
                IController(controller).treasury(),
                _keepLQDR
            );

            _lqdr = _lqdr.sub(_keepLQDR);

            _swapSushiswap(lqdr, wftm, _lqdr);
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
        }
        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

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
