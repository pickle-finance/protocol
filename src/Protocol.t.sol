pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Protocol.sol";

contract ProtocolTest is DSTest {
    Protocol protocol;

    function setUp() public {
        protocol = new Protocol();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
