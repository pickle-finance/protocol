// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-fantom-base.sol";

contract StrategyFantomSushiUsdcFtmSlp is StrategySushiFantomBase {
    // Addresses
    address private constant _lp = 0xA48869049e36f8Bfe0Cc5cf655632626988c0140;
    uint256 private constant _poolId = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiFantomBase(_lp, _poolId, _governance, _strategist, _controller, _timelock) {
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
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFantomSushiUsdcFtmSlp";
    }
}
