// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-arb-base.sol";

contract StrategyArbSushiEthGohmSlp is StrategySushiArbBase {
    address private constant _lp = 0xaa5bD49f2162ffdC15634c87A77AC67bD51C6a6D;
    uint256 private constant _pid = 12;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiArbBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = false;

        // Native to token0

        // Native to token1
        address[] memory _p1 = new address[](2);
        _p1[0] = native;
        _p1[1] = token1;
        bytes[] memory _encodedToken1Route = new bytes[](1);
        _encodedToken1Route[0] = abi.encode(true, abi.encode(_p1));
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
        address[] memory _pr = new address[](2);
        _pr[0] = reward;
        _pr[1] = native;
        bytes[] memory _encodedRewardRoute = new bytes[](1);
        _encodedRewardRoute[0] = abi.encode(true, abi.encode(_pr));
        _addToNativeRoute(abi.encode(_encodedRewardRoute));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyArbSushiEthGohmSlp";
    }
}
