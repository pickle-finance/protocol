pragma solidity ^0.6.7;

import "../../lib/erc20.sol";

contract WithdrawLusd {
    using SafeERC20 for IERC20;

    function withdrawAll() external {
        address lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
        address governance = 0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C;

        IERC20(lusd).safeTransfer(governance, IERC20(lusd).balanceOf(address(this)));
    }
}