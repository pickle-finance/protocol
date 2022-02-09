pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/hades-chef.sol";

abstract contract StrategyHadesFarmBase is StrategyBase {
    address public hades = 0x88C37E0bc6a237e96bc4A82774A38BBc30efF3Cf;
    address public hellshare = 0xEfB15eF34f85632fd1D4C17FC130CcEe3D3D48aE;
    address public masterchef = 0xcd66208ac05f75069C0f3a345ADf438FB3B53C1A;
    address public token0;
    address public token1;

    // How much HELLSHARE tokens to keep?
    uint256 public keepHELLSHARE = 1000;
    uint256 public constant keepHELLSHAREMax = 10000;

    mapping(address => address[]) public swapRoutes;

    uint256 public poolId;

    // **** Getters ****
    constructor(
        address _want,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        sushiRouter = 0x81b9FA50D5f5155Ee17817C21702C3AE4780AD09;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(hellshare).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IHadesChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 pending = IHadesChef(masterchef).pendingShare(
            poolId,
            address(this)
        );
        return pending;
    }

    // **** Setters ****

    function setKeepHELLSHARE(uint256 _keepHELLSHARE) external {
        require(msg.sender == timelock, "!timelock");
        keepHELLSHARE = _keepHELLSHARE;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            IHadesChef(masterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IHadesChef(masterchef).withdraw(poolId, _amount);
        return _amount;
    }

    function harvest() public override {
        IHadesChef(masterchef).deposit(poolId, 0);
        uint256 _hellshare = IERC20(hellshare).balanceOf(address(this));

        if (_hellshare > 0) {
            uint256 _keepHELLSHARE = _hellshare.mul(keepHELLSHARE).div(keepHELLSHAREMax);
            IERC20(hellshare).safeTransfer(
                IController(controller).treasury(),
                _keepHELLSHARE
            );

            _hellshare = _hellshare.sub(_keepHELLSHARE);
            uint256 toToken0 = _hellshare.div(2);
            uint256 toToken1 = _hellshare.sub(toToken0);

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
