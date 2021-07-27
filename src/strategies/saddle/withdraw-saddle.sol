/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.6.7;
import "../../interfaces/saddle-farm.sol";
import "../../interfaces/erc20.sol";

contract WithdrawSaddle {
  
    address public staking = 0x0639076265e9f88542C91DCdEda65127974A5CA5;
    address public want = 0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A;
    address public saddle_strategy = 0x4A974495E20A8E0f5ce1De59eB15CfffD19Bcf8d;
    address public governance = 0xacfe4511ce883c14c4ea40563f176c3c09b4c47c;

    function withdraw(uint256 _amount) external {
        LockedStake[] memory lockedStakes = ICommunalFarm(staking)
        .lockedStakesOf(saddle_strategy);

        uint256 _sum = 0;
        uint256 count = 0;
        uint256 i;

        for (i = 0; i < lockedStakes.length; i++) {
            _sum = _sum.add(lockedStakes[i].liquidity);
            count++;
            if (_sum >= _amount) break;
        }
        for (i = 0; i < count; i++) {
            ICommunalFarm(staking).withdrawLocked(lockedStakes[i].kek_id);
        }
        uint256 _balance = IERC20(want).balanceOf(saddle_strategy);
        require(_balance >= _amount, "withdraw-failed");

        IERC20(want).safeTransfer(governance, _amount);
    }
}