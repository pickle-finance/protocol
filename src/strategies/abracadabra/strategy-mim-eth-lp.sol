// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-abracadabra-base.sol";

contract StrategyMimEthLp is StrategyAbracadabraFarmBase {
    address public mim_eth_lp = 0x07D5695a24904CC1B6e3bd57cC7780B90618e3c4;
    uint256 public mim_eth_poolId = 2;
    address public mim = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAbracadabraFarmBase(
            mim_eth_lp,
            mim_eth_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMimEthLp";
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
            uint256 _swap = _ice.sub(_keepIce);
            IERC20(ice).safeApprove(sushiRouter, 0);
            IERC20(ice).safeApprove(sushiRouter, _swap);
            _swapSushiswap(ice, weth, _swap);
        }

        uint256 _weth = IERC20(weth).balanceOf(address(this));

        if (_weth > 0) {
            uint256 _amount = _weth.div(2);
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _amount);
            _swapSushiswap(weth, mim, _amount);
        }

        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _mim = IERC20(mim).balanceOf(address(this));

        if (_weth > 0 && _mim > 0) {
            IERC20(mim).safeApprove(sushiRouter, 0);
            IERC20(mim).safeApprove(sushiRouter, _mim);

            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            UniswapRouterV2(sushiRouter).addLiquidity(
                mim,
                weth,
                _mim,
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

            IERC20(mim).safeTransfer(
                IController(controller).treasury(),
                IERC20(mim).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}
