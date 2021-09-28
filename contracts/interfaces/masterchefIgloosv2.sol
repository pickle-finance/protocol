pragma solidity 0.6.12;

import "../lib/erc20.sol";
import "../lib/reentrancy-guard.sol";
import "../lib/ownable,sol";

// interface for MasterChefIglooV2 contract
interface IMasterChefIglooV2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

      /* Reads */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
         }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        external view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PEFIs on frontend.
    function pendingPEFI(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return user.amount.mul(accPEFIPerShare).div(1e12).sub(user.rewardDebt);
    }


      /* Writes */

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _withdrawFeeBP,
        bool _withUpdate
    ) external {}

    // Update the given pool's PEFI allocation point and withdrawal fee.
    // Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _withdrawFeeBP,
        bool _withUpdate
    ) external {}

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external {}

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external {}

    // Deposit LP tokens to MasterChef for PEFI allocation.
    function deposit(uint256 _pid, uint256 _amount) external {}

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {}

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {}

    // Safe pefi transfer function, just in case if rounding error causes pool to not have enough PEFIs.
    function safePEFITransfer(address _to, uint256 _amount) internal {}

    // Update dev address by the previous dev.
    function dev(address _devaddr) external {}

    function setFeeAddress(address _feeAddress) external {}

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _pefiPerBlock) external {}
}
