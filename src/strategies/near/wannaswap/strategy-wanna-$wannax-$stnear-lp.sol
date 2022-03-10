// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base-v2.sol";

contract StrategyWannaWannaxStnearLp is StrategyWannaFarmBaseV2 {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_wannax_wanna_poolid = 2;
    // Token addresses
    address public wanna_wannax_wanna_lp =
        0xE22606659ec950E0328Aa96c7f616aDC4907cBe3;
    address public wannax = 0x5205c30bf2E37494F8cF77D2c19C6BA4d2778B9B;
    address public stnear = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;
    address public meta = 0xc21Ff01229e982d7c8b8691163B0A3Cb8F357453;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBaseV2(
            meta,
            wanna_wannax_wanna_poolid,
            wanna_wannax_wanna_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[wanna] = [meta, stnear, near, wanna];
        swapRoutes[stnear] = [wanna, near, stnear];
        swapRoutes[wannax] = [stnear, wannax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaxStnearLp";
    }

    function harvestTwo() public override onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        if (_extraReward > 0) {
            _swapSushiswapWithPath(swapRoutes[wanna], _extraReward);
        }
    }

    function harvestThree() public override onlyBenevolent {
        uint256 _wanna = IERC20(wanna).balanceOf(address(this));
        uint256 _keepReward = _wanna.mul(keepREWARD).div(keepREWARDMax);
        IERC20(wanna).safeTransfer(
            IController(controller).treasury(),
            _keepReward
        );

        _wanna = IERC20(wanna).balanceOf(address(this));
        _swapSushiswapWithPath(swapRoutes[stnear], _wanna);

        uint256 stnear = IERC20(stnear).balanceOf(address(this));
        _swapSushiswapWithPath(swapRoutes[wannax], _wanna.div(2));
    }
}
