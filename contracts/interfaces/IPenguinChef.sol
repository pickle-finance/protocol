pragma solidity ^0.6.7;

import "./masterchefIgloosv2.sol";

interface IPenguinChef is IMasterChef {
    function pefi() external view returns (address);
    function pefiPerBlock() external view returns (uint256);
    function pendingPEFI(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo(uint pid) external view returns (
        address lpToken,
        uint allocPoint,
        uint lastRewardBlock,
        uint accPEFIPerShare,
        uint16 withdrawFeeBP
    );
}