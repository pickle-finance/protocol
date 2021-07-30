// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-abracadabra-base.sol";

contract StrategySpellEthLp is StrategyAbracadabraFarmBase {
    address public spell_eth_lp = 0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E;
    uint256 public spell_eth_poolId = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAbracadabraFarmBase(
            spell_eth_lp,
            spell_eth_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpellEthLp";
    }

    function harvest() public override onlyBenevolent {
        ISorbettiereFarm(sorbettiere).deposit(poolId, 0);
        uint256 _ice = IERC20(ice).balanceOf(address(this));

        if (_ice > 0) {
            // 10% is locked up for future gov
            uint256 _keepIce = _ice.mul(keepIce).div(keepIceMax);
            IERC20(ice).safeTransfer(
                IController(controller).treasury(),
                _keepIce
            );
            uint256 _swap = (_ice.sub(_keepIce)).div(2);
            IERC20(ice).safeApprove(sushiRouter, 0);
            IERC20(ice).safeApprove(sushiRouter, _swap);
            _swapSushiswap(ice, weth, _swap);
        }

        uint256 _weth = IERC20(weth).balanceOf(address(this));
        _ice = IERC20(ice).balanceOf(address(this));

        if (_weth > 0 && _ice > 0) {
            IERC20(ice).safeApprove(sushiRouter, 0);
            IERC20(ice).safeApprove(sushiRouter, _ice);

            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            UniswapRouterV2(sushiRouter).addLiquidity(
                ice,
                weth,
                _ice,
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

            IERC20(ice).safeTransfer(
                IController(controller).treasury(),
                IERC20(ice).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}
