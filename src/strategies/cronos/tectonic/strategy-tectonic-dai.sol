// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tectonic-base.sol";

contract StrategyTectonicDai is StrategyTectonicBase {
    // Token addresses
    address public constant dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;
    address public constant cdai = 0xE1c4c56f772686909c28C319079D41adFD6ec89b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTectonicBase(
            dai,
            cdai,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTectonicDai";
    }
}
