// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../sushiswap/strategy-sushi-bento-base.sol";

abstract contract StrategySushiFantomBase is StrategySushiBentoBase {
    address private constant _tridentRouter = address(0);
    address private constant _sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant _bento = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
    address private constant _minichef = 0xf731202A3cf7EfA9368C2d7bD613926f7A144dB5;
    address private constant _sushi = 0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC;
    address private constant _native = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

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
