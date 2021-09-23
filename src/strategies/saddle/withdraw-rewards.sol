pragma solidity ^0.6.7;

import "../../lib/erc20.sol";

contract WithdrawRewards {
    using SafeERC20 for IERC20;

    function withdraw() external {
        address fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
        address tribe = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;
        address alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
        address lqty = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;

        address target = 0x4f1f43B54a1d88024d26Ad88914e6FCFe0024cB6;

        IERC20(fxs).safeTransfer(target, IERC20(fxs).balanceOf(address(this)));
        IERC20(tribe).safeTransfer(target, IERC20(tribe).balanceOf(address(this)));
        IERC20(alcx).safeTransfer(target, IERC20(alcx).balanceOf(address(this)));
        IERC20(lqty).safeTransfer(target, IERC20(lqty).balanceOf(address(this)));
    }
}
