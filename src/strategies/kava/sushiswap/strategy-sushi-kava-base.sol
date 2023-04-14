// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../sushiswap/strategy-sushi-bento-base.sol";

abstract contract StrategySushiKavaBase is StrategySushiBentoBase {
    address private constant _tridentRouter = 0xbE811A0D44E2553d25d11CB8DC0d3F0D0E6430E6;
    address private constant _sushiRouter = address(0);
    address private constant _bento = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address private constant _minichef = 0xf731202A3cf7EfA9368C2d7bD613926f7A144dB5;
    address private constant _sushi = 0x7C598c96D02398d89FbCb9d41Eab3DF0C16F227D;
    address private constant _native = 0xc86c7C0eFbd6A49B35E8714C5f59D99De09A225b;

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
        ITridentRouter.Path[] memory _p = new ITridentRouter.Path[](1);
        _p[0] = ITridentRouter.Path({
            pool: 0x52089cd962A5665498aEA8D57576e2d3f68eb47D,
            data: abi.encode(sushi, address(this), true)
        });
        bytes[] memory _encodedFullRouteArr = new bytes[](1);
        _encodedFullRouteArr[0] = abi.encode(false, abi.encode(_p));
        _addToNativeRoute(abi.encode(_encodedFullRouteArr));
    }
}
