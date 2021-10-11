// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";

import "../../../interfaces/staking-rewards.sol";


contract DpxDepositTest {
    using SafeERC20 for IERC20;

    // Token addresses
    address public want = 0x0C1Cf6883efA1B496B01f654E247B9b419873054;
    address public rewards = 0x96B0d9c85415C69F4b2FAC6ee9e9CE37717335B4;

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }
}

