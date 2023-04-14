// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-kava-base.sol";

contract StrategyKavaSushiKavaScplp is StrategySushiKavaBase {
    address private constant _lp = 0x52089cd962A5665498aEA8D57576e2d3f68eb47D;
    uint256 private constant _pid = 6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiKavaBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        ITridentRouter.Path[] memory _p0 = new ITridentRouter.Path[](1);
        _p0[0] = ITridentRouter.Path({
            pool: 0x52089cd962A5665498aEA8D57576e2d3f68eb47D,
            data: abi.encode(native, address(this), true)
        });
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(false, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

        // Native to token1
        
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
        return "StrategyKavaSushiKavaScplp";
    }
}
