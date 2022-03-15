// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-bankerjoe-farm-base.sol";

contract StrategyBankerJoeDaiE is StrategyBankerJoeFarmBase {
    address public constant daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70; //banker joe deposit token
    address public constant jDAIE = 0xc988c170d0E38197DC634A45bF00169C7Aa7CA19; //lending receipt token

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBankerJoeFarmBase(
            daiE, 
            jDAIE, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(jToken, 0);
            IERC20(want).safeApprove(jToken, _want);
            require(IJToken(jToken).mint(_want) == 0, "!deposit");
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
            // Make sure market can cover liquidity
            require(IJToken(jToken).getCash() >= _redeem, "!cash-liquidity");
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
            require(IJToken(jToken).redeemUnderlying(_redeem) == 0, "!redeem");
        }
        return _amount;
    }

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBankerJoeDaiE";
    }
}