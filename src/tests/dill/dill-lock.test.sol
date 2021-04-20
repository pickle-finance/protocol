// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "../lib/test-defi-base.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/dill.sol";

contract DillLockTest is DSTestDefiBase {
    IDill dill = IDill(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf);
    address dev = 0x1CbF903De5D688eDa7D6D895ea2F0a8F2A521E99;

    function setUp() public {
        // Send 100 Pickles to dev
        _getERC20(pickle, 100 * 10 ** 18);
        IERC20(pickle).transfer(dev, 100 * 10 ** 18);
    }

    // function _test_uni_lp_swap(address lp1, address lp2) internal {
    //     _getUniV2LPToken(lp1, 20 ether);
    //     uint256 _balance = IERC20(lp1).balanceOf(address(this));

    //     uint256 _before = IERC20(lp2).balanceOf(address(this));
    //     IERC20(lp1).safeIncreaseAllowance(address(pickleSwap), _balance);
    //     pickleSwap.convertWETHPair(lp1, lp2, _balance);
    //     uint256 _after = IERC20(lp2).balanceOf(address(this));

    //     assertTrue(_after > _before);
    //     assertTrue(_after > 0);
    // }

    // function test_pickleswap_dai_usdc() public {
    //     _test_uni_lp_swap(
    //         univ2Factory.getPair(weth, dai),
    //         univ2Factory.getPair(weth, usdc)
    //     );
    // }

    // function test_pickleswap_dai_usdt() public {
    //     _test_uni_lp_swap(
    //         univ2Factory.getPair(weth, dai),
    //         univ2Factory.getPair(weth, usdt)
    //     );
    // }

    // function test_pickleswap_usdt_susd() public {
    //     _test_uni_lp_swap(
    //         univ2Factory.getPair(weth, usdt),
    //         univ2Factory.getPair(weth, susd)
    //     );
    // }
}
