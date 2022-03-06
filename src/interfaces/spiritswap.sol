// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;


interface ISpiritGaugeProxy {

    function getGauge(address _token) external view returns (address);
    function tokens() external view returns (address[] memory);

}

interface ISpiritMasterChef {
    function userInfo(uint, address) external view returns (uint, uint);
    function deposit(uint, uint) external;
    function withdraw(uint, uint) external;
}

interface ISpiritGauge {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function depositAll() external;
    function deposit(uint256 amount) external;
    function withdrawAll() external;
    function withdraw(uint256 amount) external;
    function getReward() external;
}