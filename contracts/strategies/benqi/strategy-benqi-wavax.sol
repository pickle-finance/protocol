// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiWavax is StrategyQiFarmBase {

        address public constant qiavax = 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c; //lending receipt token

        constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            wavax, 
            qiavax, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));

        // get the value of Native Avax in the contract
        uint256 _avax = address(this).balance;


        if (_want > 0) {
            // unwrap wavax to avax for benqi
            WAVAX(want).withdraw(_want);

            // confirm that msg.sender received avax
            require(address(this).balance >= _want, "!unwrap unsuccessful");

            // mint qiTokens external payable
            IQiAvax(qiavax).mint{value: _want}();

            // confirm that qiTokens is received in exchange
            require( IQiToken(qiavax).balanceOf(address(this)) > 0 , "qitokens not received" );
        }
        //check if there is a balance of Native Avax Outstanding
        if (_avax > 0) {
            // confirm that msg.sender received avax
            require(address(this).balance >= _avax, "!unwrap unsuccessful");

            // mint qiTokens external payable
            IQiAvax(qiavax).mint{value: _avax}();

            // confirm that qiTokens is received in exchange
            require( IQiToken(qiavax).balanceOf(address(this)) > 0 , "qitokens not received" );
        }
    }
    
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        uint256 _want = balanceOfWant();

        if (_want < _amount) {
            uint256 _redeem = _amount.sub(_want);

            // Make sure market can cover liquidity
            require(IQiToken(qiavax).getCash() >= _redeem, "!cash-liquidity");

            // How much borrowed amount do we need to free?
            uint256 borrowed = getBorrowed();
            uint256 supplied = getSupplied();
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);

            // If the amount we need to free is > borrowed
            // Just free up all the borrowed amount
            if (borrowed > 0) {
                if (borrowedToBeFree > borrowed) {
                    this.deleverageToMin();
                } else {
                    // Otherwise just keep freeing up borrowed amounts until
                    // we hit a safe number to redeem our underlying
                    this.deleverageUntil(supplied.sub(borrowedToBeFree));
                }
            }
            
            // Redeems underlying
            require(IQiToken(qiavax).redeemUnderlying(_redeem) == 0, "!redeem");

            // wrap avax to wavax
            WAVAX(wavax).deposit{value: _redeem}();

            // confirm contract address now holds enough wavax;
            require(IERC20(want).balanceOf(address(this)) >= _amount, "!NotEnoughWavax");
        }
        return _amount;
    }
        // Deleverages until we're supplying <x> amount
    // 1. Redeem <x> want
    // 2. Repay <x> want
    function deleverageUntil(uint256 _supplyAmount) public override onlyKeepers {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(
            _supplyAmount >= unleveragedSupply && _supplyAmount <= supplied,
            "!deleverage"
        );

        // Market collateral factor
        uint256 marketColFactor = getMarketColFactor();

        // How much can we redeem
        uint256 _redeemAndRepay = getRedeemable();
        do {
            // If the amount we're redeeming is exceeding the
            // target supplyAmount, adjust accordingly
            if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                _redeemAndRepay = supplied.sub(_supplyAmount);
            }

            require(
                IQiAvax(qiToken).redeemUnderlying(_redeemAndRepay) == 0,
                "!redeem"
            );
            IERC20(want).safeApprove(qiToken, 0);
            IERC20(want).safeApprove(qiToken, _redeemAndRepay);
            IQiAvax(qiToken).repayBorrow{value: _redeemAndRepay}();

            supplied = supplied.sub(_redeemAndRepay);

            // After each deleverage we can redeem more (the colFactor)
            _redeemAndRepay = _redeemAndRepay.mul(1e18).div(marketColFactor);
        } while (supplied > _supplyAmount);
    }
    
    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiAvax";
    }
}