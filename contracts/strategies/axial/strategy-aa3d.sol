// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-3pool-base.sol";

contract StrategyAxialAA3DLp is StrategyAxial3PoolBase {
    // stablecoins
    address public avai = 0x346A59146b9b4a77100D369a3d18E8007A9F46a6;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    uint256 public am3d_poolId = 4; 
    address public lp = ;
    address public swapLoan = ;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial3PoolBase(
        swapLoan,
        mim,
        usdcE,
        avai, 
        am3d_poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock

    ){}

     // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAA3DLp";
    }
}