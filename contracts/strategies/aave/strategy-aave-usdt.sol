// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";
import "../../lib/exponential.sol";

import "../../interfaces/globe.sol";
import "../../interfaces/pangolin.sol";
import "../../interfaces/controller.sol";
import "../../interfaces/aave.sol";

import "../strategy-base.sol";
import "../strategy-joe-farm-base.sol";

contract StrategyAaveUsdt is StrategyBase, Exponential {
    address public constant avusdt = 0x532E6537FEA298397212F09A61e03311686f548e;
    address public constant usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant variableDebtUsdt =
        0xfc1AdA7A288d6fCe0d29CcfAAa57Bc9114bb2DbE;
    address public constant lendingPool =
        0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    address public constant incentivesController =
        0x01D83Fe6A10D2f2B7AF17034343746188272cAc9;

    uint256 public constant usdt_COLFACTOR = 0;
    uint16 public constant REFERRAL_CODE = 0xaa;

    // Require a 0.04 buffer between
    // market collateral factor and strategy's collateral factor
    // when leveraging.
    uint256 colFactorLeverageBuffer = 40;
    uint256 colFactorLeverageBufferMax = 1000;

    // Keeper bots
    // Maintain leverage within buffer
    mapping(address => bool) keepers;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(usdt, _governance, _strategist, _controller, _timelock)
    {}

    // **** Modifiers **** //

    modifier onlyKeepers() {
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

    function getName() external pure override returns (string memory) {
        return "StrategyAaveUsdtV3";
    }

    function getSuppliedView() public view returns (uint256) {
        return IERC20(avusdt).balanceOf(address(this));
    }

    function getBorrowedView() public view returns (uint256) {
        return IERC20(variableDebtUsdt).balanceOf(address(this));
    }

    function balanceOfPool() public view override returns (uint256) {
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

    function getMarketColFactor() public pure returns (uint256) {
        return usdt_COLFACTOR;
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

    function getWavaxAccrued() public view returns (uint256) {
        address[] memory avTokens = new address[](1);
        avTokens[0] = avusdt;

        return
            IAaveIncentivesController(incentivesController).getRewardsBalance(
                avTokens,
                address(this)
            );
    }

    function getColFactor() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public view returns (uint256) {
        return IERC20(avusdt).balanceOf(address(this));
    }

    function getBorrowed() public view returns (uint256) {
        return IERC20(variableDebtUsdt).balanceOf(address(this));
    }

    function getBorrowable() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(marketColFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getRedeemable() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // Return 99.99% of the time just incase
        return
            supplied.sub(borrowed.mul(1e18).div(marketColFactor)).mul(9999).div(
                10000
            );
    }

    function getCurrentLeverage() public view returns (uint256) {
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

    // **** State mutations **** //

    // Do a `callStatic` on this.
    // If it returns true then run it for realz. (i.e. eth_signedTx, not eth_call)
    function sync() public returns (bool) {
        uint256 colFactor = getColFactor();
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // If we're not safe
        if (colFactor > safeLeverageColFactor) {
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
    // 1. Redeem <x> usdt
    // 2. Repay <x> usdt
    function leverageUntil(uint256 _supplyAmount) public onlyKeepers {
        // 1. Borrow out <X> usdt
        // 2. Supply <X> usdt

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

            ILendingPool(lendingPool).borrow(
                usdt,
                _borrowAndSupply,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                REFERRAL_CODE,
                address(this)
            );
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }

    // Deleverages until we're supplying <x> amount
    // 1. Redeem <x> usdt
    // 2. Repay <x> usdt
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
        while (supplied > _supplyAmount) {
            // If the amount we're redeeming is exceeding the
            // target supplyAmount, adjust accordingly
            if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                _redeemAndRepay = supplied.sub(_supplyAmount);
            }

            // withdraw
            require(
                ILendingPool(lendingPool).withdraw(
                    usdt,
                    _redeemAndRepay,
                    address(this)
                ) != 0,
                "!withdraw"
            );

            IERC20(usdt).safeApprove(lendingPool, 0);
            IERC20(usdt).safeApprove(lendingPool, _redeemAndRepay);

            // repay
            require(
                ILendingPool(lendingPool).repay(
                    usdt,
                    _redeemAndRepay,
                    uint256(DataTypes.InterestRateMode.VARIABLE),
                    address(this)
                ) != 0,
                "!repay"
            );

            supplied = supplied.sub(_redeemAndRepay);

            // After each deleverage we can redeem more (the colFactor)
            _redeemAndRepay = _redeemAndRepay.mul(1e18).div(marketColFactor);
        }
    }

    function harvest() public override onlyBenevolent {
        address[] memory avTokens = new address[](1);
        avTokens[0] = avusdt;

        IAaveIncentivesController(incentivesController).claimRewards(
            avTokens,
            uint256(-1),
            address(this)
        );
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            _swapPangolin(wavax, want, _wavax);

        }

        _distributePerformanceFeesAndDeposit();
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(lendingPool, 0);
            IERC20(want).safeApprove(lendingPool, _want);
            ILendingPool(lendingPool).deposit(
                usdt,
                _want,
                address(this),
                REFERRAL_CODE
            );
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

            // withdraw
            require(
                ILendingPool(lendingPool).withdraw(
                    usdt,
                    _redeem,
                    address(this)
                ) != 0,
                "!withdraw"
            );
        }

        return _amount;
    }
}


