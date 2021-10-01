// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";
import "../../lib/exponential.sol";
import "../strategy-base.sol";
import "../../interfaces/globe.sol";
import "../../interfaces/pangolin.sol";
import "../../interfaces/controller.sol";
import "../../interfaces/benqi.sol";
import "../../interfaces/wavax.sol";

contract StrategyQiFarmBase is StrategyBase, Exponential {
    address public constant comptroller = 0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4; // Through UniTroller Address
    address public constant benqi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5; //Qi Token  
    
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
        address token,
        address qiToken,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(token, _governance, _strategist, _controller, _timelock)
    {
        // Enter qiToken Market
        address[] memory qitokens = new address[](1);
        qitokens[0] = qiToken;
        IComptroller(comptroller).enterMarkets(qitokens);
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

    function getName() external override pure returns (string memory) {
        return "StrategQiFarmBase";
    }

    function getSuppliedView() public view returns (uint256) {
        (, uint256 qiTokenBal, , uint256 exchangeRate) = IQiToken(qiToken)
            .getAccountSnapshot(address(this)
        );

        (, uint256 bal) = mulScalarTruncate(
            Exp({mantissa: exchangeRate}),
            qiTokenBal
        );

        return bal;
    }

    function getBorrowedView() public view returns (uint256) {
        return IQiToken(qiToken).borrowBalanceStored(address(this));
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
        (, uint256 colFactor) = IComptroller(comptroller).markets(qiToken);

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
        return IQiToken(qiToken).balanceOfUnderlying(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return IQiToken(qiToken).borrowBalanceCurrent(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IComptroller(comptroller).markets(qiToken);

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(colFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getRedeemable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IComptroller(comptroller).markets(qiToken);

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
    // 1. Redeem <x> token
    // 2. Repay <x> token
    function leverageUntil(uint256 _supplyAmount) public onlyKeepers {
        // 1. Borrow out <X> token
        // 2. Supply <X> token

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

            IQiToken(qiToken).borrow(_borrowAndSupply);
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }

    // Deleverages until we're supplying <x> amount
    // 1. Redeem <x> token
    // 2. Repay <x> token
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
                IQiToken(qiToken).redeemUnderlying(_redeemAndRepay) == 0,
                "!redeem"
            );
            IERC20(token).safeApprove(qiToken, 0);
            IERC20(token).safeApprove(qiToken, _redeemAndRepay);
            require(IQiToken(qiToken).repayBorrow(_redeemAndRepay) == 0, "!repay");

            supplied = supplied.sub(_redeemAndRepay);

            // After each deleverage we can redeem more (the colFactor)
            _redeemAndRepay = _redeemAndRepay.mul(1e18).div(marketColFactor);
        } while (supplied > _supplyAmount);
    }
    
    
    // allow Native Avax
    receive() external payable {}

    function harvest() public override onlyBenevolent {
        address[] memory qitokens = new address[](1);
        qitokens[0] = qiToken;

        IComptroller(comptroller).claimReward(0, address(this)); //ClaimQi
        if (want != benqi) {
            uint256 _benqi = IERC20(benqi).balanceOf(address(this));
            if (_benqi > 0) {
                _swapPangolin(benqi, want, _benqi);
            }
        }
            IComptroller(comptroller).claimReward(1, address(this)); //ClaimAvax
            uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, want, _wavax);
        }

        _distributePerformanceFeesAndDeposit();
    }
    
    //Calculate the Accrued Rewards
    function getHarvestable() external view returns (uint256, uint256) {
        uint rewardsQi = _calculateHarvestable(0, address(this));
        uint rewardsAvax = _calculateHarvestable(1, address(this));
        
        return (rewardsQi, rewardsAvax);
    }

    function _calculateHarvestable(uint8 tokenIndex, address account) internal view returns (uint) {
        uint rewardAccrued = IComptroller(comptroller).rewardAccrued(tokenIndex, account);
        (uint224 supplyIndex, ) = IComptroller(comptroller).rewardSupplyState(tokenIndex, account);
        uint supplierIndex = IComptroller(comptroller).rewardSupplierIndex(tokenIndex, qiToken, account);
        uint supplyIndexDelta = 0;
        if (supplyIndex > supplierIndex) {
            supplyIndexDelta = supplyIndex - supplierIndex; 
        }
        uint supplyAccrued = IQiToken(qiToken).balanceOf(account).mul(supplyIndexDelta);
        (uint224 borrowIndex, ) = IComptroller(comptroller).rewardBorrowState(tokenIndex, account);
        uint borrowerIndex = IComptroller(comptroller).rewardBorrowerIndex(tokenIndex, qiToken, account);
        uint borrowIndexDelta = 0;
        if (borrowIndex > borrowerIndex) {
            borrowIndexDelta = borrowIndex - borrowerIndex;
        }
        uint borrowAccrued = IQiToken(qiToken).borrowBalanceStored(account).mul(borrowIndexDelta);
        return rewardAccrued.add(supplyAccrued.sub(borrowAccrued));
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(qiToken, 0);
            IERC20(want).safeApprove(qiToken, _want);
            require(IQiToken(qiToken).mint(_want) == 0, "!deposit");
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
            require(IQiToken(token).getCash() >= _redeem, "!cash-liquidity");
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
            require(IQiToken(token).redeemUnderlying(_redeem) == 0, "!redeem");
        }
        return _amount;
    }

}