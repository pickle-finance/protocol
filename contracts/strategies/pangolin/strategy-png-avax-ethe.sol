// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxEthELp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_weth_lp_rewards = 0x830A966B9B447c9B15aB24c0369c4018E75F31C9;
    address public png_avax_weth_lp = 0x7c05d54fc5CB6e4Ad87c6f5db3b807C94bB89c52;
    address public weth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            weth,
            png_avax_weth_lp_rewards,
            png_avax_weth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxEthELp";
    }
}
