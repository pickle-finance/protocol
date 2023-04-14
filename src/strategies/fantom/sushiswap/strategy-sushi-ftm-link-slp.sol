// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-fantom-base.sol";

contract StrategyFantomSushiFtmLinkSlp is StrategySushiFantomBase {
    // Addresses
    address private constant _lp = 0x1Ca86e57103564F47fFCea7259a6ce8Cc1301549;
    uint256 private constant _poolId = 7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiFantomBase(_lp, _poolId, _governance, _strategist, _controller, _timelock) {
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
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFantomSushiFtmLinkSlp";
    }
}
