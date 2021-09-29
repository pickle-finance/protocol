pragma solidity ^0.6.7;

import "../lib/erc20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
}