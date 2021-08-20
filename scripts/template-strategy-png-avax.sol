// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvax<token>Lp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_<token>_lp_rewards = <rewards>;;
    address public png_avax_<token>_lp = <lp>;
    address public <token> = <token_addr>;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            <token>,
            png_avax_<token>_lp_rewards,
            png_avax_<token>_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvax<token>Lp";
    }
}
