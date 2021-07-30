pragma solidity ^0.6.7;

import "../../lib/erc20.sol";

contract WithdrawRewards {
    using SafeERC20 for IERC20;

    function withdraw() external {
        address fxs = 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0;
        address tribe = 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b;
        address alcx = 0xdbdb4d16eda451d0503b854cf79d55697f90c8df;
        address lqty = 0x6dea81c8171d0ba574754ef6f8b412f2ed88c54d;

        address target = 0x4f1f43b54a1d88024d26ad88914e6fcfe0024cb6;

        IERC20(fxs).safeTransfer(target, IERC20(fxs).balanceOf(address(this)));
        IERC20(tribe).safeTransfer(target, IERC20(tribe).balanceOf(address(this)));
        IERC20(alcx).safeTransfer(target, IERC20(alcx).balanceOf(address(this)));
        IERC20(lqty).safeTransfer(target, IERC20(lqty).balanceOf(address(this)));
    }
}
