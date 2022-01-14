pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/netswap-chef.sol";

abstract contract StrategyNettFarmLPBase is StrategyBase {
    address public nett = 0x90fE084F877C65e1b577c7b2eA64B8D8dd1AB278;
    address public masterchef = 0x9d1dbB49b2744A1555EDbF1708D64dC71B0CB052;
    address public token0;
    address public token1;

    // How much NETT tokens to keep?
    uint256 public keepNETT = 1000;
    uint256 public constant keepNETTMax = 10000;

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
        sushiRouter = 0x1E876cCe41B7b844FDe09E38Fa1cf00f213bFf56;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(nett).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = INettChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        (uint256 pendingNETT, , , ) = INettChef(masterchef).pendingTokens(
            poolId,
            address(this)
        );
        return pendingNETT;
    }

    // **** Setters ****

    function setKeepNETT(uint256 _keepNETT) external {
        require(msg.sender == timelock, "!timelock");
        keepNETT = _keepNETT;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            INettChef(masterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        INettChef(masterchef).withdraw(poolId, _amount);
        return _amount;
    }

    function harvest() public override {
        INettChef(masterchef).deposit(poolId, 0);
        uint256 _nett = IERC20(nett).balanceOf(address(this));

        if (_nett > 0) {
            uint256 _keepNETT = _nett.mul(keepNETT).div(keepNETTMax);
            IERC20(nett).safeTransfer(
                IController(controller).treasury(),
                _keepNETT
            );

            _nett = _nett.sub(_keepNETT);
            uint256 toToken0 = _nett.div(2);
            uint256 toToken1 = _nett.sub(toToken0);

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
