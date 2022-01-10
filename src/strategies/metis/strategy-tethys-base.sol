pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/tethys-chef.sol";

abstract contract StrategyTethysFarmLPBase is StrategyBase {
    address public tethysRouter = 0x81b9FA50D5f5155Ee17817C21702C3AE4780AD09;
    address public tethys = 0x69fdb77064ec5c84FA2F21072973eB28441F43F3;
    address public masterchef = 0x54A8fB8c634dED694D270b78Cb931cA6bF241E21;
    address public token0;
    address public token1;

    // How much TETHYS tokens to keep?
    uint256 public keepTETHYS = 1000;
    uint256 public constant keepTETHYSMax = 10000;

    mapping(address => address[]) public uniswapRoutes;

    uint256 public poolId;

    // **** Getters ****
    constructor(
        address _token0,
        address _token1,
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
        sushiRouter = tethysRouter;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , ) = ITethysChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ITethysChef(masterchef).pendingTethys(poolId, address(this));
    }

    // **** Setters ****

    function setKeepTETHYS(uint256 _keepTETHYS) external {
        require(msg.sender == timelock, "!timelock");
        keepTETHYS = _keepTETHYS;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            ITethysChef(masterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ITethysChef(masterchef).withdraw(poolId, _amount);
        return _amount;
    }

    function harvest() public override {
        ITethysChef(masterchef).deposit(poolId, 0);
        uint256 _tethys = IERC20(tethys).balanceOf(address(this));

        if (_tethys > 0) {
            uint256 _keepTETHYS = _tethys.mul(keepTETHYS).div(keepTETHYSMax);
            IERC20(tethys).safeTransfer(
                IController(controller).treasury(),
                _keepTETHYS
            );

            _tethys = _tethys.sub(_keepTETHYS);
            uint256 toToken0 = _tethys.div(2);
            uint256 toToken1 = _tethys.sub(toToken0);

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
