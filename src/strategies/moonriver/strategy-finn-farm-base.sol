// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
import "../../interfaces/oxd-chef.sol";

abstract contract StrategyOxdFarmBase is StrategyBase {
    // Token addresses
    address public constant oxd = 0xc165d941481e68696f43EE6E99BFB2B23E0E3114;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public constant oxdChef =
        0xa7821C3e9fC1bF961e280510c471031120716c3d;
========
import "../../interfaces/finn-chef.sol";

abstract contract StrategyFinnFarmBase is StrategyBase {
    // Token addresses
    address public constant finn = 0x9A92B5EBf1F6F6f7d93696FCD44e5Cf75035A756;
    address public constant finnChef =
        0x1f4b7660b6AdC3943b5038e3426B33c1c0e343E6;
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol

    address public token0;
    address public token1;

<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
    // How much OXD tokens to keep?
    uint256 public keepOXD = 420;
    uint256 public constant keepOXDMax = 10000;
========
    // How much FINN tokens to keep?
    uint256 public keepFINN = 1000;
    uint256 public constant keepFINNMax = 10000;
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol

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
<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
        // Spooky router
        sushiRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IOxdChef(oxdChef).userInfo(poolId, address(this));
========
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IFinnChef(finnChef).userInfo(
            poolId,
            address(this)
        );
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
        return IOxdChef(oxdChef).pendingOXD(poolId, address(this));
========
        return IFinnChef(finnChef).pendingReward(poolId, address(this));
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
            IERC20(want).safeApprove(oxdChef, 0);
            IERC20(want).safeApprove(oxdChef, _want);
            IOxdChef(oxdChef).deposit(poolId, _want);
========
            IERC20(want).safeApprove(finnChef, 0);
            IERC20(want).safeApprove(finnChef, _want);
            IFinnChef(finnChef).deposit(poolId, _want);
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
        IOxdChef(oxdChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepOXD(uint256 _keepOXD) external {
        require(msg.sender == timelock, "!timelock");
        keepOXD = _keepOXD;
========
        IFinnChef(finnChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepFINN(uint256 _keepFINN) external {
        require(msg.sender == timelock, "!timelock");
        keepFINN = _keepFINN;
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol
    }

    // **** State Mutations ****

<<<<<<<< HEAD:src/strategies/fantom/strategy-oxd-lp-farm-base.sol
    function harvest() public virtual override {
        // Collects OXD tokens
        IOxdChef(oxdChef).deposit(poolId, 0);
        uint256 _oxd = IERC20(oxd).balanceOf(address(this));

        if (_oxd > 0) {
            uint256 _keepOXD = _oxd.mul(keepOXD).div(keepOXDMax);
            IERC20(oxd).safeTransfer(
                IController(controller).treasury(),
                _keepOXD
            );
            _oxd = _oxd.sub(_keepOXD);
            uint256 toToken0 = _oxd.div(2);
            uint256 toToken1 = _oxd.sub(toToken0);
========
    function harvest() public override onlyBenevolent {
        // Collects FINN tokens
        IFinnChef(finnChef).deposit(poolId, 0);
        uint256 _finn = IERC20(finn).balanceOf(address(this));

        if (_finn > 0) {
            uint256 _keepFINN = _finn.mul(keepFINN).div(keepFINNMax);
            IERC20(finn).safeTransfer(
                IController(controller).treasury(),
                _keepFINN
            );
            _finn = _finn.sub(_keepFINN);
            uint256 toToken0 = _finn.div(2);
            uint256 toToken1 = _finn.sub(toToken0);
>>>>>>>> master:src/strategies/moonriver/strategy-finn-farm-base.sol

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
