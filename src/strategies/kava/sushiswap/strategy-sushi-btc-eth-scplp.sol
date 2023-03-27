// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-sushi-kava-base.sol";

contract StrategyKavaSushiBtcEthScplp is StrategySushiKavaBase {
    address private constant _lp = 0x8070cfc234C4b7f3Ec2AE873885390973f5b15C0;
    uint256 private constant _pid = 8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategySushiKavaBase(_lp, _pid, _governance, _strategist, _controller, _timelock) {
        // Pool type
        isBentoPool = true;

        // Native to token0
        ITridentRouter.Path[] memory _p0 = new ITridentRouter.Path[](2);
        _p0[0] = ITridentRouter.Path({
            pool: 0xe9c40Af74FCfb85B38Db2a74a7d5d22D731660f5,
            data: abi.encode(native, 0x8070cfc234C4b7f3Ec2AE873885390973f5b15C0, false)
        });
        _p0[1] = ITridentRouter.Path({
            pool: 0x8070cfc234C4b7f3Ec2AE873885390973f5b15C0,
            data: abi.encode(token1, address(this), true)
        });
        bytes[] memory _encodedToken0Route = new bytes[](1);
        _encodedToken0Route[0] = abi.encode(false, abi.encode(_p0));
        _addToTokenRoute(abi.encode(token0, _encodedToken0Route));

        // Native to token1
        ITridentRouter.Path[] memory _p1 = new ITridentRouter.Path[](1);
        _p1[0] = ITridentRouter.Path({
            pool: 0xe9c40Af74FCfb85B38Db2a74a7d5d22D731660f5,
            data: abi.encode(native, address(this), true)
        });
        bytes[] memory _encodedToken1Route = new bytes[](1);
        _encodedToken1Route[0] = abi.encode(false, abi.encode(_p1));
        _addToTokenRoute(abi.encode(token1, _encodedToken1Route));
        
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
        return "StrategyKavaSushiBtcEthScplp";
    }
}
