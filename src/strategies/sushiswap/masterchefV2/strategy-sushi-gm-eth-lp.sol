// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiGmEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_gm_eth_poolId = 41;

    address public sushi_gm_eth_lp = 0x4e726311E7036d7be9A9B2A1E9e00c48aEEc28Ae;
    address public gm = 0x7F0693074F8064cFbCf9fA6E5A3Fa0e4F58CcCCF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_gm_eth_poolId,
            sushi_gm_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and GM tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _gm = IERC20(gm).balanceOf(address(this));
        if (_gm > 0) {
            uint256 _amount = _gm.div(2);
            IERC20(gm).safeApprove(sushiRouter, 0);
            IERC20(gm).safeApprove(sushiRouter, _amount);
            _swapSushiswap(gm, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, gm, _amount);
        }

        // Adds in liquidity for GM/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _gm = IERC20(gm).balanceOf(address(this));

        if (_weth > 0 && _gm > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(gm).safeApprove(sushiRouter, 0);
            IERC20(gm).safeApprove(sushiRouter, _gm);

            UniswapRouterV2(sushiRouter).addLiquidity(
                gm,
                weth,
                _gm,
                _weth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(gm).safeTransfer(
                IController(controller).treasury(),
                IERC20(gm).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiGmEthLp";
    }
}
