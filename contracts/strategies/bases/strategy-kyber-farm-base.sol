// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "./strategy-kyber-base.sol";

/// @notice This is a kyber farm base contract for KyberSwap
abstract contract StrategyKyberFarm is StrategyKyberBase {

    address public gauge;

    address public vesting = 0xE79bfc312328Ab75272785DBf5Bd871b253709A5;

    uint256 internal constant Q112 = 2**112;

    uint256 poolId; 

    constructor(
        address _gauge,
        uint256 _poolId, 
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyKyberBase(
        _want, 
        _governance, 
        _strategist, 
        _controller, 
        _timelock
    )
    {
        poolId = _poolId;
        gauge = _gauge; 
    } 

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ,) = IKyber(gauge).getUserInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    // ***** Get the pending token of the pool on frontend ***** // 
    function getHarvestable() external view returns (uint256) {
        uint256[] memory pendingQi = IKyber(
            gauge
        ).pendingRewards(poolId, address(this));
        return pendingQi[0];
    }


    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            IKyber(gauge).deposit(poolId,_want, false);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256){
        IKyber(gauge).withdraw(poolId, _amount);
        return _amount;
    }

    /// @notice that we are taking the fee from wavax to snob using TraderJoe's 
    /// router and not KyberSwap because the KyberSwap network swap fees are high 
    function _takeFeeWavaxToSnob(uint256 _keep) internal {
        IERC20(wavax).safeApprove(joeRouter, 0);
        IERC20(wavax).safeApprove(joeRouter, _keep);
        _swapTraderJoe(wavax, snob, _keep); 
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