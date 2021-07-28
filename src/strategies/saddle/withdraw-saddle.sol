pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../../interfaces/saddle-farm.sol";
import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

contract WithdrawSaddle {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function withdraw(uint256 _amount) external {
        address staking = 0x0639076265e9f88542C91DCdEda65127974A5CA5;
        address want = 0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A;
        address governance = 0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C;

        LockedStake[] memory lockedStakes = ICommunalFarm(staking)
        .lockedStakesOf(address(this));

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
        uint256 _balance = IERC20(want).balanceOf(address(this));
        require(_balance >= _amount, "withdraw-failed");

        IERC20(want).safeTransfer(governance, _amount);
    }
}
