// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-arb-base.sol";

contract StrategyArbSushiRdpxEthSlp is StrategySushiArbBase {
    address private constant _lp = 0x7418F5A2621E13c05d1EFBd71ec922070794b90a;
    uint256 private constant _pid = 23;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiArbBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = false;

        // Native to token0
        address[] memory _p0 = new address[](2);
        _p0[0] = native;
        _p0[1] = token0;
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(true, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

        // Native to token1

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
        address[] memory _pr = new address[](2);
        _pr[0] = reward;
        _pr[1] = native;
        bytes[] memory _encodedRewardRoute = new bytes[](1);
        _encodedRewardRoute[0] = abi.encode(true, abi.encode(_pr));
        _addToNativeRoute(abi.encode(_encodedRewardRoute));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyArbSushiRdpxEthSlp";
    }
}
