// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-swapr-base.sol";

contract StrategySwaprGnoXdaiLp is StrategySwaprFarmBase {
    // Addresses
    address private _lp = 0xD7b118271B1B7d26C9e044Fc927CA31DccB22a5a;
    address private _rewarder = 0x9060531E0e291Aa88c10BBE1e8388FF53904e576;

    // Reward tokens
    address private constant swapr = 0x532801ED6f82FFfD2DAB70A19fC2d7B2772C4f4b;
    address private constant gno = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address private constant cow = 0x177127622c4A00F3d409B75571e12cB3c8973d3c;

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
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprGnoXdaiLp";
    }
}
