// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IJoeBar {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
	
	function approve(address spender, uint256 amount) external returns (bool);
	
	function transfer(address recipient, uint256 amount) external returns (bool);
	
	function enter(uint256 _amount) external;
	
	function leave(uint256 _share) external;
}