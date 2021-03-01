// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for 1inch farming contract
import "../lib/erc20.sol";

interface IOneInchFarm {

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getReward() external;
}