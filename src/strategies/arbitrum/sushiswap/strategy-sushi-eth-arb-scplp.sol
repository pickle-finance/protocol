// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-arb-base.sol";

contract StrategyArbSushiEthArbScplp is StrategySushiArbBase {
    address private constant _lp = 0xf3f54a80Cf28d44a0d097c4a67c4c04Eb30da0b5;
    uint256 private constant _pid = 27;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiArbBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0

        // Native to token1
        ITridentRouter.Path[] memory _p1 = new ITridentRouter.Path[](1);
        _p1[0] = ITridentRouter.Path({
            pool: 0xf3f54a80Cf28d44a0d097c4a67c4c04Eb30da0b5,
            data: abi.encode(native, address(this), true)
        });
        bytes[] memory _encodedToken1Route = new bytes[](1);
        _encodedToken1Route[0] = abi.encode(false, abi.encode(_p1));
        _addToTokenRoute(abi.encode(token1, _encodedToken1Route));

        // Approvals
        if (isBentoPool == true) {
            IERC20(token0).approve(bentoBox, type(uint256).max);
            IERC20(token1).approve(bentoBox, type(uint256).max);
        } else {
            IERC20(token0).approve(sushiRouter, type(uint256).max);
            IERC20(token1).approve(sushiRouter, type(uint256).max);
        }

        // Reward to native route
        _setRewarder(false);
        ITridentRouter.Path[] memory _pr = new ITridentRouter.Path[](1);
        _pr[0] = ITridentRouter.Path({
            pool: 0xf3f54a80Cf28d44a0d097c4a67c4c04Eb30da0b5,
            data: abi.encode(reward, address(this), true)
        });
        bytes[] memory _encodedRewardRoute = new bytes[](1);
        _encodedRewardRoute[0] = abi.encode(false, abi.encode(_pr));
        _addToNativeRoute(abi.encode(_encodedRewardRoute));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyArbSushiEthArbScplp";
    }
}
