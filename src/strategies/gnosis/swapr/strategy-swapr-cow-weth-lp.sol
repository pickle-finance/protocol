// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-swapr-base.sol";

contract StrategySwaprCowWethLp is StrategySwaprFarmBase {
    // Token addresses
    address private _lp = 0x8028457E452D7221dB69B1e0563AA600A059fab1;
    address private _rewarder = 0x90C7362D97B7d9875AE5beC489CD0cb2585F45F9;

    // Reward tokens
    address private constant swapr = 0x532801ED6f82FFfD2DAB70A19fC2d7B2772C4f4b;
    address private constant gno = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address private constant cow = 0x177127622c4A00F3d409B75571e12cB3c8973d3c;

    // LP tokens
    address private constant weth = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySwaprFarmBase(_rewarder, _lp, _governance, _strategist, _controller, _timelock) {
        // add reward tokens paths
        address[] memory _swaprRoute = new address[](2);
        _swaprRoute[0] = swapr;
        _swaprRoute[1] = native;

        address[] memory _cowRoute = new address[](2);
        _cowRoute[0] = cow;
        _cowRoute[1] = native;

        address[] memory _gnoRoute = new address[](2);
        _gnoRoute[0] = gno;
        _gnoRoute[1] = native;

        _addToNativeRoute(_swaprRoute);
        _addToNativeRoute(_cowRoute);
        _addToNativeRoute(_gnoRoute);

        nativeToTokenRoutes[cow] = [native, cow];
        nativeToTokenRoutes[weth] = [native, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprCowWethLp";
    }
}
