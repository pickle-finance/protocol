// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiAvax is StrategyQiFarmBase {

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
        if (_want > 0) {
            //unwrap wavax to avax for benqi
            WAVAX(want).withdraw(_want);
            //make sure the contract address receives avax
            IERC20(want).safeApprove(qiavax, 0);
            IERC20(want).safeApprove(qiavax, _want);
            //IqiToken.mint external payable
            require(IQiToken(qiavax).mint(_want) == 0, "!deposit");
        }
    }
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _want = balanceOfWant();
        if (_want < _amount) {
            uint256 _redeem = _amount.sub(_want);

            //unwrap wavax to avax for benqi
            WAVAX(want).withdraw(_redeem);
            // Make sure market can cover liquidity
            require(IQiToken(qiavax).getCash() >= _redeem, "!cash-liquidity");

            // How much borrowed amount do we need to free?
            uint256 borrowed = getBorrowed();
            uint256 supplied = getSupplied();
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);
            // If the amount we need to free is > borrowed
            // Just free up all the borrowed amount
            if (borrowedToBeFree > borrowed) {
                this.deleverageToMin();
            } else {
                // Otherwise just keep freeing up borrowed amounts until
                // we hit a safe number to redeem our underlying
                this.deleverageUntil(supplied.sub(borrowedToBeFree));
            }

            // Redeems underlying
            require(IQiToken(qiavax).redeemUnderlying(_redeem) == 0, "!redeem");
            //wrap avax to wavax
            WAVAX(want).deposit();
            //confirm contract address now holds enough wavax;
            require(IERC20(want).balanceOf(address(this)) >= _amount, "!NotEnoughWavax");
        }

        return _amount;
    }

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiAvax";
    }
}