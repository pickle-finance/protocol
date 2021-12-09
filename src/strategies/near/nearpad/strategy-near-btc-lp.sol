// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyBtcNearLp is StrategyNearPadFarmBase {
    uint256 public near_btc_poolid = 13;
    // Token addresses
    address public near_btc_lp = 0xA188D79D6bdbc1120a662DE9eB72384E238AF104;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            near,
            btc,
            near_btc_poolid,
            near_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[btc] = [pad, near, btc];
        swapRoutes[near] = [pad, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBtcNearLp";
    }
}
