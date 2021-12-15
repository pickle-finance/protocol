// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-4pool-base.sol";

contract StrategyAxialAC4DLp is StrategyAxial4PoolBase {
    // stablecoins
    address public tsd = 0x4fbf0429599460D327BD5F55625E30E4fC066095;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64; 
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    uint256 public ac4d_poolId = 1; 
    address public lp = 0x4da067E13974A4d32D342d86fBBbE4fb0f95f382;
    address public swapLoan = 0x8c3c1C6F971C01481150CA7942bD2bbB9Bc27bC7;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial4PoolBase(
        swapLoan, 
        tsd,
        mim,
        frax,
        daiE, 
        ac4d_poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock
    ){}

     // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAC4DLp";
    }
}