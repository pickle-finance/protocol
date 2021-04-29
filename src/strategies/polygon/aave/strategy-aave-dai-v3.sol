// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";
import "../../../lib/exponential.sol";
import "../../../interfaces/jar.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/controller.sol";
import "../../../interfaces/aave.sol";

import "./strategy-base.sol";

contract StrategyAaveDaiV3 is StrategyBase, Exponential {
    address public constant amdai = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant stableDebtDai = 0x2238101B7014C279aaF6b408A284E49cDBd5DB55;
    address public constant variableDebtDai = 0x75c4d1Fb84429023170086f06E682DcbBF537b7d;
    address public constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant lendingPool = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address public constant incentivesController = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;

    uint256 public constant DAI_COLFACTOR = 750000000000000000;
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
        StrategyBase(dai, _governance, _strategist, _controller, _timelock)
    {
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
        return "StrategyAaveUsdtV3";
    }

    function getSuppliedView() public view returns (uint256) {
        return IERC20(amdai).balanceOf(address(this));
    }

    function getBorrowedView() public view returns (uint256) {
        return IERC20(variableDebtDai).balanceOf(address(this));
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

    function getMarketColFactor() public view returns (uint256) {
        return DAI_COLFACTOR;
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

    function getMaticAccrued() public returns (uint256) {
        address[] memory amTokens = new address[](1);
        amTokens[0] = amdai;

        return IAaveIncentivesController(incentivesController).getRewardsBalance(amTokens, address(this));
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
        return IERC20(amdai).balanceOf(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return IERC20(variableDebtDai).balanceOf(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(marketColFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getRedeemable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // Return 99.99% of the time just incase
        return
            supplied.sub(borrowed.mul(1e18).div(marketColFactor)).mul(9999).div(
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
    // 1. Redeem <x> DAI
    // 2. Repay <x> DAI
    function leverageUntil(uint256 _supplyAmount) public onlyKeepers {
        // 1. Borrow out <X> DAI
        // 2. Supply <X> DAI

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

            ILendingPool(lendingPool).borrow(dai, _borrowAndSupply, uint256(DataTypes.InterestRateMode.VARIABLE), REFERRAL_CODE, address(this));
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }

    // Deleverages until we're supplying <x> amount
    // 1. Redeem <x> DAI
    // 2. Repay <x> DAI
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
            require (ILendingPool(lendingPool).withdraw(dai, _redeemAndRepay, address(this)) != 0, "!withdraw");

            IERC20(dai).safeApprove(lendingPool, 0);
            IERC20(dai).safeApprove(lendingPool, _redeemAndRepay);
            
            // repay
            require(ILendingPool(lendingPool).repay(dai, _redeemAndRepay, uint256(DataTypes.InterestRateMode.VARIABLE), address(this)) != 0, "!repay");

            supplied = supplied.sub(_redeemAndRepay);
            
            // After each deleverage we can redeem more (the colFactor)
            _redeemAndRepay = _redeemAndRepay.mul(1e18).div(marketColFactor);
        }
    }

    function harvest() public override onlyBenevolent {
        address[] memory amTokens = new address[](1);
        amTokens[0] = amdai;

        IAaveIncentivesController(incentivesController).claimRewards(amTokens, uint256(-1), address(this));
        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(univ2Router2, 0);
            IERC20(wmatic).safeApprove(univ2Router2, _wmatic);
            _swapUniswap(wmatic, want, _wmatic);
        }

        _distributePerformanceFeesAndDeposit();
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(lendingPool, 0);
            IERC20(want).safeApprove(lendingPool, _want);
            ILendingPool(lendingPool).deposit(dai, _want, address(this), REFERRAL_CODE);
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
            if (borrowedToBeFree > borrowed) {
                this.deleverageToMin();
            } else {
                // Otherwise just keep freeing up borrowed amounts until
                // we hit a safe number to redeem our underlying
                this.deleverageUntil(supplied.sub(borrowedToBeFree));
            }

            // withdraw
            require (ILendingPool(lendingPool).withdraw(dai, _redeem, address(this)) != 0, "!withdraw");
        }

        return _amount;
    }
}
