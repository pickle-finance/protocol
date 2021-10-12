// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";
import "../lib/exponential.sol";
import "./strategy-joe-base.sol";
import "../interfaces/globe.sol";
import "../interfaces/pangolin.sol";
import "../interfaces/controller.sol";
import "../interfaces/bankerjoe.sol";
import "../interfaces/wavax.sol";

abstract contract StrategyBankerJoeFarmBase is StrategyJoeBase, Exponential {
    address public constant joetroller = 0xdc13687554205E5b89Ac783db14bb5bba4A1eDaC; // Through UniTroller Address
    address public constant joeLens = 0x997fbA28c75747417571c5F3fe50015AaC2BB073; 
       
    address public jToken;

    // Require a 0.04 buffer between
    // market collateral factor and strategy's collateral factor
    // when leveraging.
    uint256 colFactorLeverageBuffer = 40;
    uint256 colFactorLeverageBufferMax = 1000;

    // Allow a 0.03 buffer
    // between market collateral factor and strategy's collateral factor
    // until we have to deleverage
    // This is so we can hit max leverage and keep accruing interest
    uint256 colFactorSyncBuffer = 30;
    uint256 colFactorSyncBufferMax = 1000;

    // Keeper bots
    // Maintain leverage within buffer
    mapping(address => bool) keepers;

    constructor(
        address _token,
        address _jToken,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeBase(_token, _governance, _strategist, _controller, _timelock)
    {
        jToken = _jToken;
        // Enter jToken Market
        address[] memory jTokens = new address[](1);
        jTokens[0] = jToken;
        IJoetroller(joetroller).enterMarkets(jTokens);
    }

    // **** Modifiers **** //

    modifier onlyKeepers {
        require(
            keepers[msg.sender] ||
            msg.sender == address(this) ||
            msg.sender == strategist ||
            msg.sender == governance,
            "!keepers"
        );
        _;
    }

    // **** Views **** //

    function getSuppliedView() public view returns (uint256) {
        (, uint256 jTokenBal, , uint256 exchangeRate) = IJToken(jToken)
            .getAccountSnapshot(address(this)
        );

        (, uint256 bal) = mulScalarTruncate(
            Exp({mantissa: exchangeRate}),
            jTokenBal
        );

        return bal;
    }

    function getBorrowedView() public view returns (uint256) {
        return IJToken(jToken).borrowBalanceStored(address(this));
    }

    function balanceOfPool() public override view returns (uint256) {
        uint256 supplied = getSuppliedView();
        uint256 borrowed = getBorrowedView();
        return supplied.sub(borrowed);
    }

    // Given an unleveraged supply balance, return the target
    // leveraged supply balance which is still within the safety buffer
    function getLeveragedSupplyTarget(uint256 supplyBalance)
        public
        view
        returns (uint256)
    {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(
            colFactorLeverageBuffer.mul(1e18).div(colFactorLeverageBufferMax)
        );

        return safeColFactor;
    }

    function getSafeSyncColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(
            colFactorSyncBuffer.mul(1e18).div(colFactorSyncBufferMax)
        );

        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        (, uint256 colFactor) = IJoetroller(joetroller).markets(jToken);

        return colFactor;
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // Infinite geometric series
        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }

     // **** Pseudo-view functions (use `callStatic` on these) **** //
    /* The reason why these exists is because of the nature of the
       interest accruing supply + borrow balance. The "view" methods
       are technically snapshots and don't represent the real value.
       As such there are pseudo view methods where you can retrieve the
       results by calling `callStatic`.
    */

    function getJoeAccrued() public returns (uint256) {
        (, , , uint256 accrued) = IJoeLens(joeLens).getJTokenBalanceInternal(
            joe,
            joetroller,
            address(this)
        );

        return accrued;
    }



    function getColFactor() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public returns (uint256) {
        return IJToken(jToken).balanceOfUnderlying(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return IJToken(jToken).borrowBalanceCurrent(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IJoetroller(joetroller).markets(jToken);

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(colFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getRedeemable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IJoetroller(joetroller).markets(jToken);

        // Return 99.99% of the time just incase
        return
            supplied.sub(borrowed.mul(1e18).div(colFactor)).mul(9999).div(
                10000
            );
    }

    function getCurrentLeverage() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    // **** Setters **** //

    function addKeeper(address _keeper) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        keepers[_keeper] = true;
    }

    function removeKeeper(address _keeper) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        keepers[_keeper] = false;
    }

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer)
        public
    {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    function setColFactorSyncBuffer(uint256 _colFactorSyncBuffer) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorSyncBuffer = _colFactorSyncBuffer;
    }

    // **** State mutations **** //

    // Do a `callStatic` on this.
    // If it returns true then run it for realz. (i.e. eth_signedTx, not eth_call)
    function sync() public returns (bool) {
        uint256 colFactor = getColFactor();
        uint256 safeSyncColFactor = getSafeSyncColFactor();

        // If we're not safe
        if (colFactor > safeSyncColFactor) {
            uint256 unleveragedSupply = getSuppliedUnleveraged();
            uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);

            deleverageUntil(idealSupply);

            return true;
        }

        return false;
    }

    function leverageToMax() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);
        leverageUntil(idealSupply);
    }

    // Leverages until we're supplying <x> amount
    // 1. Redeem <x> want
    // 2. Repay <x> want
    function leverageUntil(uint256 _supplyAmount) public onlyKeepers {
        // 1. Borrow out <X> want
        // 2. Supply <X> want

        uint256 leverage = getMaxLeverage();
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        require(
            _supplyAmount >= unleveragedSupply &&
            _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18),
            "!leverage"
        );

        // Since we're only leveraging one asset
        // Supplied = borrowed
        uint256 _borrowAndSupply;
        uint256 supplied = getSupplied();
        while (supplied < _supplyAmount) {
            _borrowAndSupply = getBorrowable();

            if (supplied.add(_borrowAndSupply) > _supplyAmount) {
                _borrowAndSupply = _supplyAmount.sub(supplied);
            }

            IJToken(jToken).borrow(_borrowAndSupply);
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }

    // Deleverages until we're supplying <x> amount
    // 1. Redeem <x> want
    // 2. Repay <x> want
    function deleverageUntil(uint256 _supplyAmount) public onlyKeepers {
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
                IJToken(jToken).redeemUnderlying(_redeemAndRepay) == 0,
                "!redeem"
            );
            IERC20(want).safeApprove(jToken, 0);
            IERC20(want).safeApprove(jToken, _redeemAndRepay);
            require(IJToken(jToken).repayBorrow(_redeemAndRepay) == 0, "!repay");

            supplied = supplied.sub(_redeemAndRepay);

            // After each deleverage we can redeem more (the colFactor)
            _redeemAndRepay = _redeemAndRepay.mul(1e18).div(marketColFactor);
        } while (supplied > _supplyAmount);
    }
    
    
    // allow Native Avax
    receive() external payable {}

    function _takeFeeWavaxToSnob(uint256 _keep) internal {
        IERC20(wavax).safeApprove(joeRouter, 0);
        IERC20(wavax).safeApprove(joeRouter, _keep);
        _swapTraderJoe(wavax, snob, _keep);
        uint _snob = IERC20(snob).balanceOf(address(this));
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

    
    function harvest() public override onlyBenevolent {
        address[] memory jTokens = new address[](1);
        jTokens[0] = jToken;
        uint256 _keep;

        IJoetroller(joetroller).claimReward(0, address(this)); //Claim
        if (want != joe) {
            uint256 _joe = IERC20(joe).balanceOf(address(this));
            if (_joe > 0) {
                _keep = _joe.mul(keep).div(keepMax);
                _takeFeeJoeToSnob(_keep);
                _swapTraderJoe(joe, want, _joe.sub(_keep));
            }
        }
        IJoetroller(joetroller).claimReward(1, address(this)); //ClaimAvax
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _keep = _wavax.mul(keep).div(keepMax);
            _takeFeeWavaxToSnob(_keep);
            _swapTraderJoe(wavax, want, _wavax.sub(_keep));
        }

        _distributePerformanceFeesAndDeposit();
    }
    
    //Calculate the Accrued Rewards
    function getHarvestable() external view returns (uint256, uint256) {
        uint rewardsJoe = _calculateHarvestable(0, address(this));
        uint rewardsAvax = _calculateHarvestable(1, address(this));
        
        return (rewardsJoe, rewardsAvax);
    }

    function _calculateHarvestable(uint8 tokenIndex, address account) internal view returns (uint) {
        uint rewardAccrued = IJoetroller(joetroller).rewardAccrued(tokenIndex, account);
        (uint224 supplyIndex, ) = IJoetroller(joetroller).rewardSupplyState(tokenIndex, account);
        uint supplierIndex = IJoetroller(joetroller).rewardSupplierIndex(tokenIndex, jToken, account);
        uint supplyIndexDelta = 0;
        if (supplyIndex > supplierIndex) {
            supplyIndexDelta = supplyIndex - supplierIndex; 
        }
        uint supplyAccrued = IJToken(jToken).balanceOf(account).mul(supplyIndexDelta);
        (uint224 borrowIndex, ) = IJoetroller(joetroller).rewardBorrowState(tokenIndex, account);
        uint borrowerIndex = IJoetroller(joetroller).rewardBorrowerIndex(tokenIndex, jToken, account);
        uint borrowIndexDelta = 0;
        if (borrowIndex > borrowerIndex) {
            borrowIndexDelta = borrowIndex - borrowerIndex;
        }
        uint borrowAccrued = IJToken(jToken).borrowBalanceStored(account).mul(borrowIndexDelta);
        return rewardAccrued.add(supplyAccrued.sub(borrowAccrued));
    }

}