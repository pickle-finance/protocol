pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/netswap-chef.sol";

abstract contract StrategyNettDualFarmLPBase is StrategyBase {
    address public constant nett = 0x90fE084F877C65e1b577c7b2eA64B8D8dd1AB278;
    address public constant masterchef =
        0x9d1dbB49b2744A1555EDbF1708D64dC71B0CB052;
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
        sushiRouter = 0x1E876cCe41B7b844FDe09E38Fa1cf00f213bFf56;
        IUniswapV2Pair pair = IUniswapV2Pair(_want);
        token0 = pair.token0();
        token1 = pair.token1();
        poolId = _poolId;
        extraReward = _extraReward;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(nett).approve(sushiRouter, uint256(-1));
        IERC20(extraReward).approve(sushiRouter, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = INettChef(masterchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable()
        external
        view
        returns (uint256 pendingNETT, uint256 pendingBonusToken)
    {
        (pendingNETT, , , pendingBonusToken) = INettChef(masterchef)
            .pendingTokens(poolId, address(this));
    }

    // **** Setters ****

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
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

        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        uint256 _nett = IERC20(nett).balanceOf(address(this));

        if (_extraReward == 0 && _nett == 0) return;

        // Swap NETT to extra reward if part of pair
        if (extraReward == token0 || extraReward == token1) {
            if (swapRoutes[extraReward].length > 1 && _nett > 0)
                _swapSushiswapWithPath(swapRoutes[extraReward], _nett);

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
        // If extra reward not part of pair, swap to NETT
        else {
            if (swapRoutes[nett].length > 1 && _extraReward > 0)
                _swapSushiswapWithPath(swapRoutes[nett], _extraReward);

            _nett = IERC20(nett).balanceOf(address(this));
            uint256 _keepNETT = _nett.mul(keepREWARD).div(keepREWARDMax);
            IERC20(extraReward).safeTransfer(
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
