// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsSingleLp is StrategyVVSFarmBase {
    uint256 public vvs_single_poolId = 17;

    // Token addresses
    address public vvs_single_lp = 0x6f72a3f6dB6F486B50217f6e721f4388994B1FBe;
    address public single = 0x0804702a4E749d39A35FDe73d1DF0B1f1D6b8347;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            vvs_single_poolId,
            vvs_single_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[single] = [vvs, single];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsSingleLp";
    }
}
