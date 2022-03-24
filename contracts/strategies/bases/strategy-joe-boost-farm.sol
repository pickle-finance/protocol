// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol";
import "../../interfaces/masterchefjoev2.sol";
import "../../interfaces/wavax.sol";

///@notice Strategy base contract for all TraderJoe Boost farms
abstract contract StrategyJoeBoostFarmBase is StrategyJoeBase{
    address public masterchefJoe = 0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F;
    uint256 public poolId; 

    constructor(
        uint256 _poolId,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) 
    public 
    StrategyJoeBase(
        _want,
        _governance,
        _strategist,
        _controller,
        _timelock
    ) 
    {
        poolId = _poolId; 
    }

    ///@notice Return the current balance of a token in a given pool
    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , ) = IMasterChefJoe(masterchefJoe).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    /// @notice Return the pending reward tokens on frontend
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 pendingJoe, , , uint256 pendingBonusToken) = IMasterChefJoe(
            masterchefJoe
        ).pendingTokens(poolId, address(this));
        return (pendingJoe, pendingBonusToken);
    }


    // **** Setters ****
    ///@notice deposit a quantity of token into MasterChef
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchefJoe, 0);
            IERC20(want).safeApprove(masterchefJoe, _want);
            IMasterChefJoe(masterchefJoe).deposit(poolId, _want);
        }
    }

    ///@notice remove a quantity of token from MasterChef
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterChefJoe(masterchefJoe).withdraw(poolId, _amount);
        return _amount;
    }   

    ///@notice exchange a quantity of token for wavax
    function _swapToWavax(address _from, uint256 _amount) internal {
        IERC20(_from).safeApprove(joeRouter, 0);
        IERC20(_from).safeApprove(joeRouter, _amount);

        _swapTraderJoe(_from, wavax, _amount);
    }
}