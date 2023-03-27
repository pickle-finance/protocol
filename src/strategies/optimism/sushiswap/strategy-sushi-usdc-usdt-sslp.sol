// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-op-base.sol";

contract StrategyOpSushiUsdcUsdtSslp is StrategySushiOpBase {
    address private constant _lp = 0xB059CF6320B29780C39817c42aF1a032bf821D90;
    uint256 private constant _pid = 4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiOpBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        ITridentRouter.Path[] memory _p0 = new ITridentRouter.Path[](1);
        _p0[0] = ITridentRouter.Path({
            pool: 0x7086622E6Db990385B102D79CB1218947fb549a9,
            data: abi.encode(native, address(this), true)
        });
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(false, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

        // Native to token1
        ITridentRouter.Path[] memory _p1 = new ITridentRouter.Path[](2);
        _p1[0] = ITridentRouter.Path({
            pool: 0x7086622E6Db990385B102D79CB1218947fb549a9,
            data: abi.encode(native, 0xB059CF6320B29780C39817c42aF1a032bf821D90, false)
        });
        _p1[1] = ITridentRouter.Path({
            pool: 0xB059CF6320B29780C39817c42aF1a032bf821D90,
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
        ITridentRouter.Path[] memory _pr = new ITridentRouter.Path[](1);
        _pr[0] = ITridentRouter.Path({
            pool: 0xaA1513Ab4622ED52DeEe4Bd2cD984Fe52F336a63,
            data: abi.encode(reward, address(this), true)
        });
        bytes[] memory _encodedRouteArr = new bytes[](1);
        _encodedRouteArr[0] = abi.encode(false, abi.encode(_pr));
        _addToNativeRoute(abi.encode(_encodedRouteArr));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOpSushiUsdcUsdtSslp";
    }
}
