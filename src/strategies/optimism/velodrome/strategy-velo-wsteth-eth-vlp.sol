// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloWstethEthVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xc6C1E8399C1c33a3f1959f2f77349D74a373345c;
    address private _gauge = 0x150dc0e12d473347BECd0f7352e9dAE6CD30d8aB;
    address private constant wsteth = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyVeloBase(
            _lp,
            _gauge,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        isStablePool = false;

        // token0 route
        nativeToTokenRoutes[wsteth].push(ISolidlyRouter.route(native, wsteth, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloWstethEthVlp";
    }
}
