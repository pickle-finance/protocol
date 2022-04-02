// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol"; 
import "../../interfaces/vtx.sol";
import "../../interfaces/wavax.sol";

import "hardhat/console.sol";

/// @notice This is a base contract for Vector single staking
abstract contract StrategyVtxSingleSidedFarmBase is StrategyJoeBase {
    // Token addresses 
    address public constant vtx = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8; 
    address public constant masterchefvtx = 0x423D0FE33031aA4456a17b150804aA57fc157d97;

    address public constant xptp = 0x060556209E507d30f2167a101bFC6D256Ed2f3e1; 
 
    constructor(
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyJoeBase(
        _want,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
    {}

    /// @notice returns the balance of the want token being staked
    function balanceOfPool() public view override returns (uint256) { 
        return IMasterChefVTX(masterchefvtx).depositInfo(xptp, address(this));
    }

    // returns earned VTX and the input token ready for harvest
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 pendingVTX, , ,uint256 pendingPTP) = IMasterChefVTX(masterchefvtx).pendingTokens(xptp, address(this), ptp);
        return (pendingVTX, pendingPTP); 
    }

    // **** Setters ****
    function deposit() public override {
        // Convert PTP to xPTP
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(xptp, 0);
            IERC20(want).approve(xptp, _want);
         
            IxPTP(xptp).deposit(_want);
        }
        // Stake xPTP to earn protocol revenue plus VTX tokens
        uint256 _xptp = IERC20(xptp).balanceOf(address(this));
        if(_xptp > 0){
            IERC20(xptp).approve(masterchefvtx, 0);
            IERC20(xptp).approve(masterchefvtx, _xptp);

            IMasterChefVTX(masterchefvtx).deposit(xptp, _xptp);
        }
    }

    /// @notice withdraws ptp from MasterChef and swaps for the want token
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {

        console.log("The amount we are looking to withdraw is", _amount); 
        
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));
        uint256 _xptp = IERC20(xptp).balanceOf(address(this));

        console.log("the value of ptp before withdrawing", _ptp);
        console.log("the value of xptp before withdrawing", _xptp);

        IMasterChefVTX(masterchefvtx).withdraw(xptp, _amount); 

        _ptp = IERC20(ptp).balanceOf(address(this));
        _xptp = IERC20(xptp).balanceOf(address(this));

        console.log("the value of ptp before withdrawing", _ptp);
        console.log("the value of xptp before withdrawing", _xptp);

        address[] memory path = new address[](2);
        path[0] = xptp;
        path[1] = ptp;

        IERC20(xptp).safeApprove(joeRouter, 0);
        IERC20(xptp).safeApprove(joeRouter, _amount);
        //_swapTraderJoeWithPath(path, _amount);

        _ptp = IERC20(ptp).balanceOf(address(this));
        _xptp = IERC20(xptp).balanceOf(address(this));

        console.log("the value of ptp before withdrawing", _ptp);
        console.log("the value of xptp before withdrawing", _xptp);
        //swap
        uint256[] memory amounts = IJoeRouter(joeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );

        _ptp = IERC20(ptp).balanceOf(address(this));
        _xptp = IERC20(xptp).balanceOf(address(this));

        console.log("the value of ptp before withdrawing", _ptp);
        console.log("the value of xptp before withdrawing", _xptp);

        console.log("the value of amount[0] in the array is", amounts[1]);

        return amounts[1];
    }

    /// @notice takes a fee from any reward token to snob
    function _takeFeeRewardToSnob(uint256 _keep, address reward) internal {
        address[] memory path = new address[](3);
        path[0] = reward;
        path[1] = wavax;
        path[2] = snob;
        IERC20(reward).safeApprove(joeRouter, 0);
        IERC20(reward).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }
}