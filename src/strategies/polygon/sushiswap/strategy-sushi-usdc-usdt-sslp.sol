// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-polygon-base.sol";

contract StrategyPolySushiUsdcUsdtSslp is StrategySushiPolyBase {
    address private constant _lp = 0x231BA46173b75E4D7cEa6DCE095A6c1c3E876270;
    uint256 private constant _pid = 62;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiPolyBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        ITridentRouter.Path[] memory _p0 = new ITridentRouter.Path[](1);
        _p0[0] = ITridentRouter.Path({
            pool: 0x846Fea3D94976ef9862040d9FbA9C391Aa75A44B,
            data: abi.encode(native, address(this), true)
        });
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(false, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

        // Native to token1
        ITridentRouter.Path[] memory _p1 = new ITridentRouter.Path[](2);
        _p1[0] = ITridentRouter.Path({
            pool: 0x846Fea3D94976ef9862040d9FbA9C391Aa75A44B,
            data: abi.encode(native, 0x231BA46173b75E4D7cEa6DCE095A6c1c3E876270, false)
        });
        _p1[1] = ITridentRouter.Path({
            pool: 0x231BA46173b75E4D7cEa6DCE095A6c1c3E876270,
            data: abi.encode(token0, address(this), true)
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
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPolySushiUsdcUsdtSslp";
    }
}
