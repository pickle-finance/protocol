// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../interfaces/uwu/uwu-lend.sol";
import "../../interfaces/uwu/data-provider.sol";
import "../../interfaces/uwu/uwu-rewards.sol";
import "../../interfaces/univ3/ISwapRouter.sol";
import {DataTypes} from "../../interfaces/uwu/data-types.sol";
import "../strategy-base-v2.sol";

abstract contract StrategyUwuBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uwu = 0x55C08ca52497e2f1534B59E2917BF524D4765257;
    address public constant lendingPool = 0x2409aF0251DCB89EE3Dee572629291f9B087c668;
    address public constant dataProviderAddr = 0x17938eDE656Ca1901807abf43a6B1D138D8Cd521;

    address public immutable aToken;
    address public immutable variableDebtToken;

    IUwuRewards uwuRewards = IUwuRewards(0x21953192664867e19F85E96E1D1Dd79dc31cCcdB);

    IUwuLocker uwuLocker = IUwuLocker(0x7c0bF1108935e7105E218BBB4f670E5942c5e237);
    IDataProvider dataProvider;

    bytes nativeToTokenPath;

    // Require a 0.04 buffer between
    // market collateral factor and strategy's collateral factor
    // when leveraging.
    uint256 colFactorLeverageBuffer = 40;
    uint256 colFactorLeverageBufferMax = 1000;

    constructor(
        address _token,
        bytes memory _path,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_token, _governance, _strategist, _controller, _timelock) {
        nativeToTokenPath = _path;

        DataTypes.ReserveData memory reserveData = IUwuLend(lendingPool).getReserveData(_token);
        aToken = reserveData.aTokenAddress;
        variableDebtToken = reserveData.variableDebtTokenAddress;
        dataProvider = IDataProvider(dataProviderAddr);

        IERC20(weth).approve(univ3Router, type(uint256).max);
    }

    // **** Modifiers **** //

    modifier onlyKeepers() {
        require(
            harvesters[msg.sender] ||
                msg.sender == address(this) ||
                msg.sender == strategist ||
                msg.sender == governance,
            "!keepers"
        );
        _;
    }

    function getSupplied() public view returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    function getBorrowed() public view returns (uint256) {
        return IERC20(variableDebtToken).balanceOf(address(this));
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        return supplied.sub(borrowed);
    }

    // Given an unleveraged supply balance, return the target
    // leveraged supply balance which is still within the safety buffer
    function getLeveragedSupplyTarget(uint256 supplyBalance) public view returns (uint256) {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(colFactorLeverageBuffer.mul(1e18).div(colFactorLeverageBufferMax));

        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        (, uint256 ltv, , , , , , , , ) = dataProvider.getReserveConfigurationData(want);

        // Scale to 18 decimal places, Aave denominates by 10000
        return ltv.mul(1e14);
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // Infinite geometric series
        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }

    function getHarvestable() external view override returns (uint256) {
        address[] memory aTokens = new address[](1);
        aTokens[0] = aToken;
        uint256[] memory rewards = uwuRewards.claimableReward(address(this), aTokens);

        return rewards[0].div(2);
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

    function getBorrowable() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // 99.99% just in case some dust accumulates
        return supplied.mul(marketColFactor).div(1e18).sub(borrowed).mul(9999).div(10000);
    }

    function getRedeemable() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // Return 99.99% of the time just incase
        return supplied.sub(borrowed.mul(1e18).div(marketColFactor)).mul(9999).div(10000);
    }

    function getCurrentLeverage() public view returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer) public {
        require(msg.sender == governance || msg.sender == strategist, "!governance");
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    function setNativeToTokenPath(bytes memory _path) public {
        require(msg.sender == governance || msg.sender == timelock, "!governance");
        nativeToTokenPath = _path;
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
            _supplyAmount >= unleveragedSupply && _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18),
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

            IUwuLend(lendingPool).borrow(
                want,
                _borrowAndSupply,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                0,
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
    // 1. Redeem <x> DAI
    // 2. Repay <x> DAI
    function deleverageUntil(uint256 _supplyAmount) public onlyKeepers {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(_supplyAmount >= unleveragedSupply && _supplyAmount <= supplied, "!deleverage");

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
            require(IUwuLend(lendingPool).withdraw(want, _redeemAndRepay, address(this)) != 0, "!withdraw");

            IERC20(want).safeApprove(lendingPool, 0);
            IERC20(want).safeApprove(lendingPool, _redeemAndRepay);

            // repay
            require(
                IUwuLend(lendingPool).repay(
                    want,
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
        address[] memory aTokens = new address[](1);
        aTokens[0] = aToken;

        uwuRewards.claim(address(this), aTokens);
        uwuLocker.exitEarly(address(this));

        uint256 _uwu = IERC20(uwu).balanceOf(address(this));
        if (_uwu > 0) {
            // First swap to ETH on Sushi, then ETH -> want on UniV3
            IERC20(uwu).safeApprove(sushiRouter, 0);
            IERC20(uwu).safeApprove(sushiRouter, _uwu);
            address[] memory path = new address[](2);
            path[0] = uwu;
            path[1] = weth;

            _swapWithPath(sushiRouter, path, _uwu);

            _distributePerformanceFeesNative();

            uint256 _weth = IERC20(weth).balanceOf(address(this));

            if (nativeToTokenPath.length > 0)
                ISwapRouter(univ3Router).exactInput(
                    ISwapRouter.ExactInputParams({
                        path: nativeToTokenPath,
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: _weth,
                        amountOutMinimum: 0
                    })
                );

            deposit();
        }
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(lendingPool, 0);
            IERC20(want).safeApprove(lendingPool, _want);
            IUwuLend(lendingPool).deposit(want, _want, address(this), 0);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
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
            require(IUwuLend(lendingPool).withdraw(want, _redeem, address(this)) != 0, "!withdraw");
        }

        return _amount;
    }
}
