pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/spooky-chef.sol";

abstract contract StrategyBooFarmLPBase is StrategyBase {
    address public boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address public masterchef = 0x2b2929E785374c651a81A63878Ab22742656DcDd;
    address public token0;
    address public token1;

    // How much BOO tokens to keep?
    uint256 public keepBOO = 1000;
    uint256 public constant keepBOOMax = 10000;

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
        sushiRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(boo).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IBooChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 pendingBOO = IBooChef(masterchef).pendingBOO(
            poolId,
            address(this)
        );
        return pendingBOO;
    }

    // **** Setters ****

    function setKeepBOO(uint256 _keepBOO) external {
        require(msg.sender == timelock, "!timelock");
        keepBOO = _keepBOO;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            IBooChef(masterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBooChef(masterchef).withdraw(poolId, _amount);
        return _amount;
    }

    function harvest() public override {
        IBooChef(masterchef).deposit(poolId, 0);
        uint256 _boo = IERC20(boo).balanceOf(address(this));

        if (_boo > 0) {
            uint256 _keepBOO = _boo.mul(keepBOO).div(keepBOOMax);
            IERC20(boo).safeTransfer(
                IController(controller).treasury(),
                _keepBOO
            );

            _boo = _boo.sub(_keepBOO);
            uint256 toToken0 = _boo.div(2);
            uint256 toToken1 = _boo.sub(toToken0);

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
