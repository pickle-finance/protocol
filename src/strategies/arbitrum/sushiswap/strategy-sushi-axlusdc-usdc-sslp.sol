// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-arb-base.sol";

contract StrategyArbSushiAxlusdcUsdcSslp is StrategySushiArbBase {
    address private constant _lp = 0x863EeD6056918258626b653065588105C54FF2AC;
    uint256 private constant _pid = 16;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiArbBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        address[] memory _p0_0 = new address[](2);
        _p0_0[0] = native;
        _p0_0[1] = token1;
        ITridentRouter.Path[] memory _p0_1 = new ITridentRouter.Path[](1);
        _p0_1[0] = ITridentRouter.Path({
            pool: 0x863EeD6056918258626b653065588105C54FF2AC,
            data: abi.encode(token1, address(this), true)
        });
        bytes[] memory _encodedToken0Route = new bytes[](2);
        _encodedToken0Route[0] = abi.encode(true, abi.encode(_p0_0));
        _encodedToken0Route[1] = abi.encode(false, abi.encode(_p0_1));
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
        return "StrategyArbSushiAxlusdcUsdcSslp";
    }
}
