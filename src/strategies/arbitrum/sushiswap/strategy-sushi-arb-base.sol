// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../sushiswap/strategy-sushi-bento-base.sol";

abstract contract StrategySushiArbBase is StrategySushiBentoBase {
    address private constant _tridentRouter = 0xD9988b4B5bBC53A794240496cfA9Bf5b1F8E0523;
    address private constant _sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant _bento = 0x74c764D41B77DBbb4fe771daB1939B00b146894A;
    address private constant _minichef = 0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3;
    address private constant _sushi = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
    address private constant _native = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

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
