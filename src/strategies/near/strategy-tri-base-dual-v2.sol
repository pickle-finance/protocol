// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichef-triv2.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategyTriDualFarmBaseV2 is StrategyBase {
    // Token addresses
    address public constant tri = 0xFa94348467f64D5A457F75F8bc40495D33c65aBB;
    address public extraReward;
    address public constant miniChef =
        0x3838956710bcc9D122Dd23863a0549ca8D5675D6;

    // WETH/<token1> pair
    address public token0;
    address public token1;

    // How much TRI tokens to keep?
    uint256 public keepTRI = 1000;
    uint256 public constant keepTRIMax = 10000;

    uint256 public keepREWARD = 1000;
    uint256 public constant keepREWARDMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _extraReward,
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
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
        extraReward = _extraReward;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(tri).approve(sushiRouter, uint256(-1));
        IERC20(extraReward).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefTri(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingTri = IMiniChefTri(miniChef).pendingTri(
            poolId,
            address(this)
        );

        IRewarder rewarder = IMiniChefTri(miniChef).rewarder(poolId);
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(
            poolId,
            address(this),
            0
        );

        uint256 _pendingExtraReward;
        if (_rewardAmounts.length > 0) {
            _pendingExtraReward = _rewardAmounts[0];
        }

        return (_pendingTri, _pendingExtraReward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IMiniChefTri(miniChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefTri(miniChef).withdraw(poolId, _amount, address(this));
        return _amount;
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
    }

    function harvestOne() public onlyBenevolent {
        IMiniChefTri(miniChef).harvest(poolId, address(this));
    }

    function harvestTwo() public virtual onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        uint256 _tri = IERC20(tri).balanceOf(address(this));

        if (extraReward == token0 || extraReward == token1) {
            if (swapRoutes[extraReward].length > 1 && _tri > 0)
                _swapSushiswapWithPath(swapRoutes[extraReward], _tri);

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
        // If extra reward not part of pair, swap to TRI
        else {
            if (swapRoutes[tri].length > 1 && _extraReward > 0)
                _swapSushiswapWithPath(swapRoutes[tri], _extraReward);

            _tri = IERC20(tri).balanceOf(address(this));
            uint256 _keepReward = _tri.mul(keepREWARD).div(keepREWARDMax);
            IERC20(tri).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _tri = _tri.sub(_keepReward);
            uint256 toToken0 = _tri.div(2);
            uint256 toToken1 = _tri.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token1], toToken1);
            }
        }
    }

    function harvestThree() public onlyBenevolent {
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

    function harvestFour() public onlyBenevolent {
        // We want to get back Tri LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
