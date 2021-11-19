// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-abracadabra-base.sol";

contract StrategyAbraMim2Crv is StrategyAbracadabraFarmBase {
    // Token addresses
    address public mim2crv = 0x30dF229cefa463e991e29D42DB0bae2e122B2AC7;
    uint256 public mimPoolId = 0;

    // Stablecoin addresses
    address public mim = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address public zapper = 0x7544Fe3d184b6B55D6B36c3FCA1157eE0Ba30287;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAbracadabraFarmBase(
            mim2crv,
            mimPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?

        // Collects SPELL tokens
        ISorbettiereFarm(sorbettiere).deposit(poolId, 0);
        uint256 _spell = IERC20(spell).balanceOf(address(this));
        if (_spell == 0) {
            return;
        }

        _swapSushiswap(spell, mim, _spell);

        // Adds liquidity to Abra's mim2pool
        uint256 _mim = IERC20(mim).balanceOf(address(this));
        if (_mim > 0) {
            IERC20(mim).safeApprove(zapper, 0);
            IERC20(mim).safeApprove(zapper, _mim);

            uint256[3] memory amounts = [_mim, 0, 0];
            ICurveZapper(zapper).add_liquidity(mim2crv, amounts, 0);
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyAbraMim2Crv";
    }
}
