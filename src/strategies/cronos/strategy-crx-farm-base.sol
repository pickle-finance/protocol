// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";

// import "../../interfaces/crx-chef.sol";

abstract contract StrategyCrxFarmBase is StrategyBase {
    // Token addresses
    address public constant crx = 0xe243CCab9E66E6cF1215376980811ddf1eb7F689;
    address public constant crxChef =
        0xC42F861Fb18c752ce7A848f1B637f05ca7ED47Fa;

    address public token0;
    address public token1;

    // How much CRX tokens to keep?
    uint256 public keepCRX = 1000;
    uint256 public constant keepCRXMax = 10000;

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
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ICrxChef(crxChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ICrxChef(crxChef).pendingCrx(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(crxChef, 0);
            IERC20(want).safeApprove(crxChef, _want);
            ICrxChef(crxChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICrxChef(crxChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepCRX(uint256 _keepCRX) external {
        require(msg.sender == timelock, "!timelock");
        keepCRX = _keepCRX;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects CRX tokens
        ICrxChef(crxChef).deposit(poolId, 0);
        uint256 _crx = IERC20(crx).balanceOf(address(this));

        if (_crx > 0) {
            uint256 _keepCRX = _crx.mul(keepCRX).div(keepCRXMax);
            IERC20(crx).safeTransfer(
                IController(controller).treasury(),
                _keepCRX
            );
            _crx = _crx.sub(_keepCRX);
            uint256 toToken0 = _crx.div(2);
            uint256 toToken1 = _crx.sub(toToken0);

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
