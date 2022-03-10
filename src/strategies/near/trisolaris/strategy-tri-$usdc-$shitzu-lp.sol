// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriUsdcShitzuLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_usdc_shitzu_poolid = 19;
    // Token addresses
    address public tri_usdc_shitzu_lp =
        0x5E74D85311fe2409c341Ce49Ce432BB950D221DE;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;
    address public shitzu = 0x68e401B61eA53889505cc1366710f733A60C2d41;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            tri,
            tri_usdc_shitzu_poolid,
            tri_usdc_shitzu_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = tri;
        swapRoutes[usdc] = [tri, usdt, usdc];
        swapRoutes[shitzu] = [usdc, shitzu];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriUsdcShitzuLp";
    }

    function harvestTwo() public override onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));

        if (_extraReward > 0) {
            uint256 _keepReward = _extraReward.mul(keepREWARD).div(
                keepREWARDMax
            );
            IERC20(extraReward).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            //Swap TRI to USDC
            _extraReward = IERC20(extraReward).balanceOf(address(this));
            _swapSushiswapWithPath(swapRoutes[usdc], _extraReward);

            // Swap half of USDC for SHITZU
            uint256 _usdc = IERC20(usdc).balanceOf(address(this));
            _swapSushiswapWithPath(swapRoutes[shitzu], _usdc.div(2));
        }
    }
}
