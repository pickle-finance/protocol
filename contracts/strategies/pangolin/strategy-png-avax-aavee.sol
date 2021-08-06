// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxAaveELp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_aave_lp_rewards = 0xa04fCcE7955312709c838982ad0E297375002C32;
    address public png_avax_aave_lp = 0x5944f135e4F1E3fA2E5550d4B5170783868cc4fE;
    address public aave = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            aave,
            png_avax_aave_lp_rewards,
            png_avax_aave_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxAaveELp";
    }
}
