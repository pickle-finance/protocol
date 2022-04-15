// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

/// @notice The strategy contract for Benqi's USDC Liquidity Pool
contract StrategyBenqiUsdc is StrategyQiFarmBase {
    
    address public constant usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // qideposit token
    address public constant qiusdc = 0xB715808a78F6041E46d61Cb123C9B4A27056AE9C; // lending receipt token

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            usdc, 
            qiusdc, 
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
        return "StrategyBenqiUsdc";
    }
}