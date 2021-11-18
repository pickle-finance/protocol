// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-3pool-base.sol";

contract StrategyAxialAM3DLp is StrategyAxial3PoolBase {
    // stablecoins
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    uint256 public am3d_poolId = 3; 
    address public lp = 0xc161E4B11FaF62584EFCD2100cCB461A2DdE64D1;
    address public swapLoan = 0x90c7b96AD2142166D001B27b5fbc128494CDfBc8;
    
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
        daiE, 
        am3d_poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock

    ){}

     // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAM3DLp";
    }
}