// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-arb-base.sol";

contract StrategyArbSushiUsdtUsdcSslp is StrategySushiArbBase {
    address private constant _lp = 0x79bf7147eBCd0d55e83Cb42ed3Ba1bB2Bb23eF20;
    uint256 private constant _pid = 21;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiArbBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        address[] memory _p0 = new address[](2);
        _p0[0] = native;
        _p0[1] = token0;
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(true, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

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
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyArbSushiUsdtUsdcSslp";
    }
}
