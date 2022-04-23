// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../interfaces/backscratcher/IStrategyProxy.sol";
import "../../interfaces/backscratcher/FraxGauge.sol";
import "../../interfaces/templeRouter.sol";

contract StrategyFraxTempleUniV2 is StrategyBase {
    address public strategyProxy;

    IERC20 public frax_temple_pool = IERC20(0x6021444f1706f15465bEe85463BCc7d7cC17Fc03);
    address public frax_temple_gauge = 0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16;

    address templeRouter = 0x8A5058100E60e8F7C42305eb505B12785bbA3BcA;

    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant TEMPLE = 0x470EBf5f030Ed85Fc1ed4C2d36B9DD02e77CF1b7;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address[] public rewardTokens = [FXS, TEMPLE];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(address(frax_temple_pool), _governance, _strategist, _controller, _timelock) {}

    // **** Views ****
    function setStrategyProxy(address _proxy) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance");
        strategyProxy = _proxy;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyFraxTempleUniV2";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        IStrategyProxy(strategyProxy).harvest(frax_temple_gauge, rewardTokens);

        uint256 _fxs = IERC20(FXS).balanceOf(address(this));

        IERC20(FXS).safeApprove(univ2Router2, 0);
        IERC20(FXS).safeApprove(univ2Router2, _fxs);

        address[] memory _path = new address[](2);
        _path[0] = FXS;
        _path[1] = FRAX;
        _swapUniswapWithPath(_path, _fxs);

        uint256 _frax = IERC20(FRAX).balanceOf(address(this));
        IERC20(FRAX).safeApprove(templeRouter, 0);
        IERC20(FRAX).safeApprove(templeRouter, _frax);

        ITempleRouter(templeRouter).swapExactFraxForTemple(_frax, 0, address(this), block.timestamp + 300);

        uint256 _temple = IERC20(TEMPLE).balanceOf(address(this));
        uint256 _amount = _temple.div(2);

        IERC20(TEMPLE).safeApprove(templeRouter, 0);
        IERC20(TEMPLE).safeApprove(templeRouter, _amount);

        ITempleRouter(templeRouter).swapExactTempleForFrax(_amount, 0, address(this), block.timestamp + 300);

        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStrategyProxy(strategyProxy).balanceOf(frax_temple_gauge);
    }

    function getHarvestable() public view returns (uint256) {
        return IFraxGaugeBase(frax_temple_gauge).earned(IStrategyProxy(strategyProxy).proxy());
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _amount = frax_temple_pool.balanceOf(address(this));
        frax_temple_pool.safeTransferFrom(address(this), strategyProxy, _amount);
        IStrategyProxy(strategyProxy).depositV2(
            frax_temple_gauge,
            address(frax_temple_pool),
            IFraxGaugeBase(frax_temple_gauge).lock_time_min()
        );
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256) {
        LockedStake[] memory lockedStakes = IStrategyProxy(strategyProxy).lockedStakesOf(frax_temple_gauge);
        uint256[2] memory _amounts;

        uint256 _sum;
        uint256 _count;

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            if (lockedStakes[i].kek_id == 0 || lockedStakes[i].liquidity == 0) {
                _count++;
                continue;
            }
            _sum = _sum.add(
                IStrategyProxy(strategyProxy).withdrawV2(
                    frax_temple_gauge,
                    address(frax_temple_pool),
                    lockedStakes[i].kek_id,
                    rewardTokens
                )
            );
            _count++;
            if (_sum >= _liquidity) break;
        }

        require(_sum >= _liquidity, "insufficient liquidity");

        LockedStake memory lastStake = lockedStakes[_count - 1];

        if (_sum > _liquidity) {
            uint128 _withdraw = uint128(uint256(lastStake.liquidity).sub(_sum.sub(_liquidity)));
            require(_withdraw <= lastStake.liquidity, "math error");

            frax_temple_pool.safeTransferFrom(address(this), strategyProxy, _withdraw);
            IStrategyProxy(strategyProxy).depositV2(
                frax_temple_gauge,
                address(frax_temple_pool),
                IFraxGaugeBase(frax_temple_gauge).lock_time_min()
            );
        }

        return (_liquidity);
    }
}
