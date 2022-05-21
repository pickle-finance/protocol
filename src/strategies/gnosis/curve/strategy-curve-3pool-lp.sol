// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";

import "../../../interfaces/jar.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/controller.sol";

import "../strategy-curve-base.sol";

contract StrategyXdaiCurve3CRV is StrategyCurveBase {
    // Curve stuff
    address public three_pool = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address public three_gauge = 0xB721Cc32160Ab0da2614CC6aB16eD822Aeebc101;
    address public three_crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;

    address public honeyRouter = 0x1C232F01118CB8B424793ae03F870aa7D0ac7f77;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyCurveBase(three_pool, three_gauge, three_crv, _governance, _strategist, _controller, _timelock) {
        IERC20(gno).approve(sushiRouter, uint256(-1));
        IERC20(crv).approve(honeyRouter, uint256(-1));
        IERC20(usdc).approve(curve, uint256(-1));
        IERC20(usdt).approve(curve, uint256(-1));
        IERC20(xdai).approve(curve, uint256(-1));
        swapRoutes[gno] = [crv, gno];
        swapRoutes[xdai] = [gno, xdai];
        swapRoutes[usdc] = [gno, xdai, usdc];
        swapRoutes[usdt] = [gno, xdai, usdt];
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (xdai, 0);
        }

        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }

        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (xdai, 0);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurve3CRV";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        // Collects tokens
        ICurveGauge(three_gauge).claim_rewards();
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        // Swap CRV to GNO through Honeyswap
        _swap(honeyRouter, swapRoutes[gno], _crv);
        uint256 _gno = IERC20(gno).balanceOf(address(this));
        if (_gno > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            uint256 _keepREWARD = _gno.mul(keepREWARD).div(keepREWARDMax);
            if (_keepREWARD > 0) {
                IERC20(gno).safeTransfer(IController(controller).treasury(), _keepREWARD);
                _gno = _gno.sub(_keepREWARD);
            }
            if (to == xdai) {
                _swap(sushiRouter, swapRoutes[xdai], _gno);
            }
            if (to == usdc) {
                _swap(sushiRouter, swapRoutes[usdc], _gno);
            }
            if (to == usdt) {
                _swap(sushiRouter, swapRoutes[usdt], _gno);
            }
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
