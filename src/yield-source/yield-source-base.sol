pragma solidity ^0.6.7;

import "../lib/yearn-affiliate-wrapper.sol";
import "../interfaces/yield-source.sol";

abstract contract YieldSourceBase is IYieldSource {
    address want;

    constructor(address _want) public {
        want = _want;
    }

    function depositToken() public view override returns (address) {
        return want;
    }
}