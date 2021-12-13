// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-tri.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyTriFarmBase is StrategyBase {
    // Token addresses
    address public constant tri = 0xFa94348467f64D5A457F75F8bc40495D33c65aBB;
    address public constant miniChef =
        0x1f1Ed214bef5E83D8f5d0eB5D7011EB965D0D79B;

    // WETH/<token1> pair
    address public token0;
    address public token1;
    address rewardToken;

    // How much TRI tokens to keep?
    uint256 public keepTRI = 1000;
    uint256 public constant keepTRIMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

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

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(tri).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefTri(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingTri = IMiniChefTri(miniChef).pendingTri(
            poolId,
            address(this)
        );

        return _pendingTri;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IMiniChefTri(miniChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefTri(miniChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setRewardToken(address _rewardToken) external {
        require(msg.sender == timelock, "!timelock");
        rewardToken = _rewardToken;
    }

    // **** State Mutations ****

    function setKeepTRI(uint256 _keepTRI) external {
        require(msg.sender == timelock, "!timelock");
        keepTRI = _keepTRI;
    }

    function harvest() public override onlyBenevolent {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
        harvestFive();
    }

    function harvestOne() public onlyBenevolent {
        // Collects TRI tokens
        IMiniChefTri(miniChef).harvest(poolId);
        uint256 _tri = IERC20(tri).balanceOf(address(this));
        uint256 _keepTRI = _tri.mul(keepTRI).div(keepTRIMax);

        IERC20(tri).safeTransfer(IController(controller).treasury(), _keepTRI);
    }

    function harvestTwo() public onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        uint256 _tri = IERC20(tri).balanceOf(address(this));
        if (_tri > 0) {
            uint256 toToken0 = _tri.div(2);

            if (swapRoutes[token0].length > 1) {
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    toToken0,
                    0,
                    swapRoutes[token0],
                    address(this),
                    now + 60
                );
            }
        }
    }

    function harvestThree() public onlyBenevolent {
        uint256 _tri = IERC20(tri).balanceOf(address(this));
        if (_tri > 0) {
            if (swapRoutes[token1].length > 1) {
                UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                    _tri, // Swap the remainder of TRI
                    0,
                    swapRoutes[token1],
                    address(this),
                    now + 60
                );
            }
        }
    }

    function harvestFour() public onlyBenevolent {
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
    }

    function harvestFive() public onlyBenevolent {
        // We want to get back Tri LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
