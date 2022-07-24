// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-swapr-base.sol";

contract StrategySwaprGnoWethLp is StrategySwaprFarmBase {
    // Token addresses
    address private _lp = 0x5fCA4cBdC182e40aeFBCb91AFBDE7AD8d3Dc18a8;
    address private _rewarder = 0xba4E93AC3544c561A6F026E12Ac0a40Ec3cA14D3;

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

        nativeToTokenRoutes[gno] = [native, gno];
        nativeToTokenRoutes[weth] = [native, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprGnoWethLp";
    }
}
