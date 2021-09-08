// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/feichefv2.sol";

abstract contract StrategyFeiFarmBaseV2 is StrategyBase {
    // Token addresses
    address public fei = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public tribe = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;

    address
        public constant feiChef = 0x9e1076cC0d19F9B0b8019F384B0a29E48Ee46f7f;

    uint256 public poolId;

    constructor(
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
    }

    function balanceOfPool() public override view returns (uint256) {
        (, uint256 virtualAmount) = IFeichefV2(feiChef).userInfo(
            poolId,
            address(this)
        );
        return virtualAmount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingTribe = IFeichefV2(feiChef).pendingRewards(
            poolId,
            address(this)
        );
        return _pendingTribe;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(feiChef, 0);
            IERC20(want).safeApprove(feiChef, _want);
            IFeichefV2(feiChef).deposit(poolId, _want, 0);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 depositLength = IFeichefV2(feiChef).openUserDeposits(
            poolId,
            address(this)
        );

        uint256[] memory amounts = new uint256[](depositLength);

        uint256 _sum = 0;
        uint256 count = 0;
        uint256 i;

        for (i = 0; i < depositLength; i++) {
            (uint256 amount, , ) = IFeichefV2(feiChef).depositInfo(
                poolId,
                address(this),
                i
            );
            amounts[i] = amount;
            _sum = _sum.add(amount);
            count++;
            if (_sum >= _amount) break;
        }
        require(_sum >= _amount, "insufficient amount");

        for (i = 0; i < count; i++) {
            uint256 _currAmount = amounts[i];
            if (_currAmount > 0)
                IFeichefV2(feiChef).withdrawFromDeposit(
                    poolId,
                    _currAmount,
                    address(this),
                    i
                );
        }
        uint256 _balance = IERC20(want).balanceOf(address(this));
        require(_balance >= _amount, "withdraw-failed");

        return _amount;
    }
}
