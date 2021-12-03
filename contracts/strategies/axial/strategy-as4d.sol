// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-4pool-base.sol";

contract StrategyAxialAS4DLp is StrategyAxial4PoolBase {
    // stablecoins
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public usdtE = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    uint256 public as4d_poolId = 0; 
    address public lp = 0x3A7387f8BA3ebFFa4A0ECcB1733e940CE2275D3f;
    address public swapLoan = 0x2a716c4933A20Cd8B9f9D9C39Ae7196A85c24228;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial4PoolBase(
        swapLoan,
        tusd, 
        usdcE,
        daiE,
        usdtE, 
        as4d_poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock

    ){}

     // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAS4DLp";
    }
}