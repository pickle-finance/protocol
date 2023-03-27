// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../sushiswap/strategy-sushi-bento-base.sol";

abstract contract StrategySushiPolyBase is StrategySushiBentoBase {
    address private constant _tridentRouter = 0x7A250C60Cde7A5Ca7B667209beAB5eA4E16eed67;
    address private constant _sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant _bento = 0x0319000133d3AdA02600f0875d2cf03D442C3367;
    address private constant _minichef = 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;
    address private constant _sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address private constant _native = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor(
        address _want,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategySushiBentoBase(
            _want,
            _sushi,
            _native,
            _bento,
            _tridentRouter,
            _sushiRouter,
            _minichef,
            _poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        performanceTreasuryFee = 1000;

        // Sushi to native route
        address[] memory _p = new address[](2);
        _p[0] = sushi;
        _p[1] = native;
        bytes[] memory _encodedFullRouteArr = new bytes[](1);
        _encodedFullRouteArr[0] = abi.encode(true, abi.encode(_p));
        _addToNativeRoute(abi.encode(_encodedFullRouteArr));
    }
}
