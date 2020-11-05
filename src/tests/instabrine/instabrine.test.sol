// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/test-defi-base.sol";

import "../../instabrine/instabrine.sol";

contract InstabrineTest is DSTestDefiBase {
    Instabrine instabrine;

    address constant p3crv = 0x1BB74b5DdC1f4fC91D6f9E7906cf68bc93538e33;
    address constant prencrv = 0x2E35392F4c36EBa7eCAFE4de34199b2373Af22ec;
    address constant pdai = 0x6949Bb624E8e8A90F87cD2058139fcd77D2F3F87;

    function setUp() public {
        instabrine = new Instabrine();
    }

    function test_instabrine_standalone() public {
        _getERC20(dai, 100e18);

        uint256 _dai = IERC20(dai).balanceOf(address(this));

        IERC20(dai).safeApprove(address(instabrine), 0);
        IERC20(dai).safeApprove(address(instabrine), _dai);

        uint256 _beforeJar = IERC20(pdai).balanceOf(address(this));

        instabrine.primitiveToPickleJar(dai, _dai, pdai);

        uint256 _afterJar = IERC20(pdai).balanceOf(address(this));

        assertTrue(_afterJar > _beforeJar);
        assertTrue(_afterJar > 0);
        assertEq(_beforeJar, 0);

        uint256 _before = IERC20(dai).balanceOf(address(this));

        IERC20(pdai).safeApprove(address(instabrine), 0);
        IERC20(pdai).safeApprove(address(instabrine), _afterJar);

        instabrine.pickleJarToPrimitive(pdai, _afterJar, dai);

        uint256 _after = IERC20(dai).balanceOf(address(this));

        assertTrue(_after > _before);
        assertTrue(_after > 0);
        assertEq(_before, 0);
    }

    function test_instabrine_2_1() public {
        _getERC20(wbtc, 4e6);

        uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));

        IERC20(wbtc).safeApprove(address(instabrine), 0);
        IERC20(wbtc).safeApprove(address(instabrine), _wbtc);

        uint256 _beforeJar = IERC20(prencrv).balanceOf(address(this));

        address[2] memory underlying = [renbtc, wbtc];
        instabrine.primitiveToCurvePickleJar_2(
            ren_pool,
            underlying,
            [uint256(0), _wbtc],
            ren_crv,
            prencrv
        );

        uint256 _afterJar = IERC20(prencrv).balanceOf(address(this));

        assertTrue(_afterJar > _beforeJar);
        assertTrue(_afterJar > 0);
        assertEq(_beforeJar, 0);

        uint256 _before = IERC20(renbtc).balanceOf(address(this));

        IERC20(prencrv).safeApprove(address(instabrine), 0);
        IERC20(prencrv).safeApprove(address(instabrine), _afterJar);

        instabrine.curvePickleJarToPrimitive_1(
            prencrv,
            _afterJar,
            ren_crv,
            ren_pool,
            int128(0),
            renbtc
        );

        uint256 _after = IERC20(renbtc).balanceOf(address(this));

        assertTrue(_after > _before);
        assertTrue(_after > 0);
        assertEq(_before, 0);
    }

    function test_instabrine_2() public {
        _getERC20(wbtc, 4e6);

        uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));

        IERC20(wbtc).safeApprove(address(instabrine), 0);
        IERC20(wbtc).safeApprove(address(instabrine), _wbtc);

        uint256 _beforeJar = IERC20(prencrv).balanceOf(address(this));

        address[2] memory underlying = [renbtc, wbtc];
        instabrine.primitiveToCurvePickleJar_2(
            ren_pool,
            underlying,
            [uint256(0), _wbtc],
            ren_crv,
            prencrv
        );

        uint256 _afterJar = IERC20(prencrv).balanceOf(address(this));

        assertTrue(_afterJar > _beforeJar);
        assertTrue(_afterJar > 0);
        assertEq(_beforeJar, 0);

        uint256[] memory _befores = new uint256[](underlying.length);
        for (uint256 i = 0; i < _befores.length; i++) {
            _befores[i] = IERC20(underlying[i]).balanceOf(address(this));
        }

        IERC20(prencrv).safeApprove(address(instabrine), 0);
        IERC20(prencrv).safeApprove(address(instabrine), _afterJar);

        instabrine.curvePickleJarToPrimitive_2(
            prencrv,
            _afterJar,
            ren_crv,
            ren_pool,
            underlying
        );

        uint256[] memory _afters = new uint256[](underlying.length);
        for (uint256 i = 0; i < _befores.length; i++) {
            _afters[i] = IERC20(underlying[i]).balanceOf(address(this));

            assertTrue(_afters[i] > _befores[i]);
            assertTrue(_afters[i] > 0);
            assertEq(_befores[i], 0);
        }
    }

    function test_instabrine_3() public {
        _getERC20(dai, 100e18);

        uint256 _dai = IERC20(dai).balanceOf(address(this));

        IERC20(dai).safeApprove(address(instabrine), 0);
        IERC20(dai).safeApprove(address(instabrine), _dai);

        uint256 _beforeJar = IERC20(p3crv).balanceOf(address(this));

        address[3] memory underlying = [dai, usdc, usdt];
        instabrine.primitiveToCurvePickleJar_3(
            three_pool,
            underlying,
            [_dai, uint256(0), uint256(0)],
            three_crv,
            p3crv
        );

        uint256 _afterJar = IERC20(p3crv).balanceOf(address(this));

        assertTrue(_afterJar > _beforeJar);
        assertTrue(_afterJar > 0);
        assertEq(_beforeJar, 0);

        uint256[] memory _befores = new uint256[](underlying.length);
        for (uint256 i = 0; i < _befores.length; i++) {
            _befores[i] = IERC20(underlying[i]).balanceOf(address(this));
        }

        IERC20(p3crv).safeApprove(address(instabrine), 0);
        IERC20(p3crv).safeApprove(address(instabrine), _afterJar);

        instabrine.curvePickleJarToPrimitive_3(
            p3crv,
            _afterJar,
            three_crv,
            three_pool,
            underlying
        );

        uint256[] memory _afters = new uint256[](underlying.length);
        for (uint256 i = 0; i < _befores.length; i++) {
            _afters[i] = IERC20(underlying[i]).balanceOf(address(this));

            assertTrue(_afters[i] > _befores[i]);
            assertTrue(_afters[i] > 0);
            assertEq(_befores[i], 0);
        }
    }

    function test_instabrine_3_1() public {
        _getERC20(dai, 100e18);

        uint256 _dai = IERC20(dai).balanceOf(address(this));

        IERC20(dai).safeApprove(address(instabrine), 0);
        IERC20(dai).safeApprove(address(instabrine), _dai);

        uint256 _beforeJar = IERC20(p3crv).balanceOf(address(this));

        address[3] memory underlying = [dai, usdc, usdt];
        instabrine.primitiveToCurvePickleJar_3(
            three_pool,
            underlying,
            [_dai, uint256(0), uint256(0)],
            three_crv,
            p3crv
        );

        uint256 _afterJar = IERC20(p3crv).balanceOf(address(this));

        assertTrue(_afterJar > _beforeJar);
        assertTrue(_afterJar > 0);
        assertEq(_beforeJar, 0);

        uint256 _before = IERC20(usdc).balanceOf(address(this));

        IERC20(p3crv).safeApprove(address(instabrine), 0);
        IERC20(p3crv).safeApprove(address(instabrine), _afterJar);

        instabrine.curvePickleJarToPrimitive_1(
            p3crv,
            _afterJar,
            three_crv,
            three_pool,
            int128(1),
            usdc
        );

        uint256 _after = IERC20(usdc).balanceOf(address(this));

        assertTrue(_after > _before);
        assertTrue(_after > 0);
        assertEq(_before, 0);
    }
}
