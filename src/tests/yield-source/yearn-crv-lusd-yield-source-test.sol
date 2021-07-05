pragma solidity ^0.6.7;

import "../lib/test-defi-base.sol";
import "../../interfaces/curve.sol";
import "../../yield-source/yearn-crv-lusd-yield-source.sol";

contract YearnCrvLusdYieldSourceTest is DSTestDefiBase {
    address public crv_lusd_lp = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    YearnCrvLusdYieldSource public source;

    function setUp() public {
        source = new YearnCrvLusdYieldSource();
    }

    function _getLp(uint256 amount) internal {
        _getERC20(lusd, amount);

        uint256[2] memory amounts;
        amounts[0] = IERC20(lusd).balanceOf(address(this));
        IERC20(lusd).approve(crv_lusd_lp, amounts[0]);
        ICurveFi_2(crv_lusd_lp).add_liquidity(amounts, 0);
    }
    
    function test_depositToken() public {
        assertTrue(source.depositToken() == crv_lusd_lp);
    }

    function test_supply_redeem() public {
        // get crv lusd lp
        _getLp(1000*10**18);
        uint256 lpAmount = IERC20(crv_lusd_lp).balanceOf(address(this));
        uint256 amount = 100*10**18;
        assertTrue(lpAmount > amount);
        // supplyTo
        assertTrue(source.balanceOfToken(address(this)) == 0);

        IERC20(crv_lusd_lp).approve(address(source), amount);

        (bool success, ) = address(source).call{gas: 3000000}(abi.encodeWithSignature("supplyTokenTo(uint256,address)", amount, address(this)));
        if (!success) {
            source.supplyTokenTo(amount, address(this));
        }

        assertEqApprox(source.balanceOfToken(address(this)), amount);

        // approve
        VaultAPI[] memory vaults = source.allVaults();
        for (uint256 id = 0; id < vaults.length; id++) {
            vaults[id].approve(address(source), uint256(-1));
        }

        // redeem half
        uint256 redeemed = source.redeemToken(amount.div(2));

        assertEqApprox(redeemed, amount.div(2));
        assertEqApprox(source.balanceOfToken(address(this)), amount.div(2));
        assertEqApprox(IERC20(crv_lusd_lp).balanceOf(address(this)), lpAmount.sub(amount.div(2)));

        // redeem all
        redeemed = source.redeemToken(uint256(-1));

        assertEqApprox(redeemed, amount.div(2));
        assertEqApprox(source.balanceOfToken(address(this)), 0);
        assertEqApprox(IERC20(crv_lusd_lp).balanceOf(address(this)), lpAmount);
    }
}