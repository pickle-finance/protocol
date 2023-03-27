// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../sushiswap/strategy-sushi-bento-base.sol";

abstract contract StrategySushiOpBase is StrategySushiBentoBase {
    address private constant _tridentRouter = 0xE52180815c81D7711B83412e53259bed6a3aB70a;
    address private constant _sushiRouter = address(0);
    address private constant _bento = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address private constant _minichef = 0xB25157bF349295a7Cd31D1751973f426182070D6;
    address private constant _sushi = 0x3eaEb77b03dBc0F6321AE1b72b2E9aDb0F60112B;
    address private constant _native = 0x4200000000000000000000000000000000000006;

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
            pool: 0xdE7629a20245058dd334025ca14Cf121349CAC10,
            data: abi.encode(sushi, address(this), true)
        });
        bytes[] memory _encodedFullRouteArr = new bytes[](1);
        _encodedFullRouteArr[0] = abi.encode(false, abi.encode(_p));
        _addToNativeRoute(abi.encode(_encodedFullRouteArr));
    }
}
