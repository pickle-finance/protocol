// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-swapr-base.sol";

contract StrategySwaprCowGnoLp is StrategySwaprFarmBase {
    // Token addresses
    address private _lp = 0xDBF14bce36F661B29F6c8318a1D8944650c73F38;
    address private _rewarder = 0x4c5c6022eb324BDb93a61f8bea64B9f549fC90Fe;

    // Reward tokens
    address private constant swapr = 0x532801ED6f82FFfD2DAB70A19fC2d7B2772C4f4b;
    address private constant cow = 0x177127622c4A00F3d409B75571e12cB3c8973d3c;
    address private constant gno = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;

    // LP tokens

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
        nativeToTokenRoutes[cow] = [native, cow];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprCowGnoLp";
    }
}
