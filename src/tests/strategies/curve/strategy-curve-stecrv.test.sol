pragma solidity ^0.6.7;

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-strategy-curve-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/steth.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";

import "../../../strategies/curve/strategy-curve-stecrv.sol";

contract StrategyCurveSteCRVTest is StrategyCurveFarmTestBase {
    IStEth public stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // lido stEth
    ICurveFi public curve = ICurveFi(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022); // stEthSwap
    address public steCRV = 0x06325440D014e39736583c165C2963BA99fAf14E; // ETH-stETH curve lp, want

    function setUp() public {
        governance = address(this);
        strategist = address(this);
        timelock = address(this);
        devfund = address(new User());
        treasury = address(new User());

        stEth.approve(address(curve), uint256(-1));
        want = steCRV;

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyCurveSteCRV(
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

        _getWant(10000 ether);
    }

    function _getWant(uint256 ethAmount) internal {
        uint256 amount = ethAmount / 2;
        stEth.submit{value: amount}(strategist);

        uint256[2] memory liquidity;
        liquidity[0] = amount;
        liquidity[1] = amount;
        curve.add_liquidity{value: amount}(liquidity, 0);
    }

    // **** Tests **** //
    function test_stecrv_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }

    function test_stecrv_withdraw() public {
        _test_withdraw();
    }
}
