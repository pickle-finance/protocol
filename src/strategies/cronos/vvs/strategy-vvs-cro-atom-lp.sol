// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsCroAtomLp is StrategyVVSFarmBase {
    uint256 public cro_atom_poolId = 13;

    // Token addresses
    address public cro_atom_lp = 0x9e5bd780dff875Dd85848a65549791445AE25De0;
    address public atom = 0xB888d8Dd1733d72681b30c00ee76BDE93ae7aa93;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            cro_atom_poolId,
            cro_atom_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [vvs, cro];
        uniswapRoutes[atom] = [vvs, cro, atom];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsCroAtomLp";
    }
}
