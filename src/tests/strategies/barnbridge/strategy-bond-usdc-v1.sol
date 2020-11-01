// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-strategy-bond-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";

import "../../../strategies/barnbridge/strategy-bond-usdc-v1.sol";

contract StrategyBondUsdcV1Test is StrategyBondFarmBase {

    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        want = usdc;

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyBondUsdcV1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        pickleJar = new PickleJar(
            strategy.want(),
            governance,
            timelock,
            address(controller)
        );

        controller.setJar(strategy.want(), address(pickleJar));
        controller.approveStrategy(strategy.want(), address(strategy));
        controller.setStrategy(strategy.want(), address(strategy));

        hevm.warp(startTime);
    }

    // **** Tests **** //

    function test_bond_usdc_v1_withdraw() public {
        _test_withdraw();
    }

    function test_bond_usdc_v1_earn_harvest_rewards() public {
        _test_earn_harvest_rewards();
    }
}
