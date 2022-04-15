// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

/// @notice The strategy contract for Benqi's USDT Liquidity Pool
contract StrategyBenqiUsdt is StrategyQiFarmBase {

        address public constant usdt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; // qideposit token
        address public constant qiusdt = 0xd8fcDa6ec4Bdc547C0827B8804e89aCd817d56EF; // lending receipt token

        constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            usdt, 
            qiusdt, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    ///@notice Deposit qideposit token into liquidity pool
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(qiToken, 0);
            IERC20(want).safeApprove(qiToken, _want);
            require(IQiToken(qiToken).mint(_want) == 0, "!deposit");
        }
    }

    ///@notice Withdraw qideposit token from liquidity pool
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _want = balanceOfWant();
        if (_want < _amount) {
            uint256 _redeem = _amount.sub(_want);
            // Make sure market can cover liquidity
            require(IQiToken(qiToken).getCash() >= _redeem, "!cash-liquidity");
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
                    // Just keep freeing up borrowed amounts until
                    // we hit a safe number to redeem our underlying
                    this.deleverageUntil(supplied.sub(borrowedToBeFree));
                }
            }
            // Redeems underlying
            require(IQiToken(qiToken).redeemUnderlying(_redeem) == 0, "!redeem");
        }
        return _amount;
    }

    // **** Views **** //
    ///@notice Return the strategy name
    function getName() external override pure returns (string memory) {
        return "StrategyBenqiUsdt";
    }
}