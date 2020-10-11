// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";
import "../../lib/exponential.sol";

import "../strategy-base.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";
import "../../interfaces/compound.sol";

contract StrategyCmpdDaiV1 is StrategyBase, Exponential {
    address
        public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant cdai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cether = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    // Safety parameters

    // Buffer between asset collateral factor
    // and collateralization ratio.
    // Originally at 5% (Should be ~DAI's interest rate)
    uint256 colRatioBuffer = 50;
    uint256 colRatioBufferMax = 1000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(dai, _governance, _strategist, _controller, _timelock)
    {
        // Enter cDAI Market
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;
        IComptroller(comptroller).enterMarkets(ctokens);
    }

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyCompoundDaiV1";
    }

    function getSuppliedAmount() public view returns (uint256) {
        (, uint256 cTokenBal, , uint256 exchangeRate) = ICToken(cdai)
            .getAccountSnapshot(address(this));

        (, uint256 bal) = mulScalarTruncate(
            Exp({mantissa: exchangeRate}),
            cTokenBal
        );

        return bal;
    }

    function balanceOfPool() public override view returns (uint256) {
        return
            getSuppliedAmount().sub(
                ICToken(cdai).borrowBalanceStored(address(this))
            );
    }

    function getTargetSupplyBalance(uint256 supplyBalance)
        public
        view
        returns (uint256)
    {
        // Infinte geometric series
        uint256 leverage = getMaxLeverage();

        return supplyBalance.mul(leverage).div(1e18);
    }

    function getCurrentLeverage() public view returns (uint256) {
        (, uint256 cTokenBal, uint256 borrowed, uint256 exchangeRate) = ICToken(
            cdai
        )
            .getAccountSnapshot(address(this));

        (, uint256 supplied) = mulScalarTruncate(
            Exp({mantissa: exchangeRate}),
            cTokenBal
        );

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        // Calculate max amount we should borrow from dydx
        // to leverage our position
        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);

        // Collateral factor with the <x>% buffer
        colFactor = colFactor.sub(
            colRatioBuffer.mul(1e18).div(colRatioBufferMax)
        );

        uint256 leverage = 1e36 / (1e18 - colFactor);

        return leverage;
    }

    // **** Pseudo-view functions (use `callStatic` on these) **** //

    // Current collateralization ratio
    function getColRatio() public returns (uint256) {
        uint256 supplied = ICToken(cdai).balanceOfUnderlying(address(this));
        uint256 borrowed = ICToken(cdai).borrowBalanceCurrent(address(this));

        return supplied.mul(1e18).div(borrowed);
    }

    // Balance of pool current (balanceOf Pool w/ interest accurred)
    function balanceOfPoolCurrent() public returns (uint256) {
        return
            ICToken(cdai).balanceOfUnderlying(address(this)).sub(
                ICToken(cdai).borrowBalanceCurrent(address(this))
            );
    }

    function borrowedBalanceCurrent() public returns (uint256) {
        return ICToken(cdai).borrowBalanceCurrent(address(this));
    }

    function getBorrowableAmount() public returns (uint256) {
        uint256 supplied = ICToken(cdai).balanceOfUnderlying(address(this));
        uint256 borrowed = ICToken(cdai).borrowBalanceCurrent(address(this));

        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);

        // 99.9% just in case some dust accomulates
        return
            supplied.mul(colFactor).div(1e18).sub(borrowed).mul(999).div(1000);
    }

    // **** Setters **** //

    function setColRatioBuffer(uint256 _colRatioBuffer) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colRatioBuffer = _colRatioBuffer;
    }

    // **** State mutations **** //

    function maxLeverage() public {
        leverageUntil(getTargetSupplyBalance(balanceOfPoolCurrent()));
    }

    // Leverages until we're supplying <x> amount
    function leverageUntil(uint256 _supplyAmount) public {
        // 1. Borrow out <X> DAI
        // 2. Supply <X> DAI

        uint256 leverage = getMaxLeverage();
        uint256 unleveragedSupply = balanceOfPoolCurrent();
        uint256 supplied = getSuppliedAmount();
        require(
            _supplyAmount >= unleveragedSupply &&
                _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18),
            "!leverage"
        );

        uint256 _borrowAndSupply;
        while (supplied < _supplyAmount) {
            _borrowAndSupply = getBorrowableAmount();

            if (supplied.add(_borrowAndSupply) > _supplyAmount) {
                _borrowAndSupply = _supplyAmount.sub(supplied);
            }

            ICToken(cdai).borrow(_borrowAndSupply);
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function maxDeleverage() public {
        deleverageUntil(balanceOf());
    }

    // Deleverages until we're supplying <x> amount
    function deleverageUntil(uint256 _supplyAmount) public {
        // 1. Redeem <x> DAI
        // 2. Repay <x> DAI

        uint256 unleveragedSupply = balanceOfPoolCurrent();
        uint256 supplied = getSuppliedAmount();
        require(
            _supplyAmount >= unleveragedSupply && _supplyAmount <= supplied,
            "!deleverage"
        );

        // Since we're only leveraging on 1 asset
        // redeemable = borrowable
        uint256 _redeemAndRepay = getBorrowableAmount();
        do {
            if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                _redeemAndRepay = supplied.sub(_supplyAmount);
            }

            ICToken(cdai).redeemUnderlying(_redeemAndRepay);
            IERC20(dai).safeApprove(cdai, 0);
            IERC20(dai).safeApprove(cdai, _redeemAndRepay);
            ICToken(cdai).repayBorrow(_redeemAndRepay);

            supplied = supplied.sub(_redeemAndRepay);
        } while (supplied > _supplyAmount);
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _want = balanceOfWant();
        if (_want < _amount) {
            // How much borrowed amount do we need to free?
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _amount.sub(_want).mul(curLeverage).div(
                1e18
            );
            uint256 borrowed = borrowedBalanceCurrent();

            // If the amount we need to free is > borrowed
            // Just free up all the borrowed amount
            if (borrowedToBeFree > borrowed) {
                maxDeleverage();
            } else {
                // Otherwise just keep freeing up borrowed amounts until
                // we hit that number
                deleverageUntil(getSuppliedAmount().sub(borrowedToBeFree));
            }

            ICToken(cdai).redeemUnderlying(_amount.sub(_want));
        }

        return _amount;
    }

    function harvest() public override onlyBenevolent {
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;

        IComptroller(comptroller).claimComp(address(this), ctokens);
        uint256 _comp = IERC20(comp).balanceOf(address(this));
        if (_comp > 0) {
            _swapUniswap(comp, want, _comp);
        }

        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            // Fees 4.5% goes to treasury
            IERC20(want).safeTransfer(
                IController(controller).treasury(),
                _want.mul(performanceFee).div(performanceMax)
            );

            deposit();
        }
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cdai, 0);
            IERC20(want).safeApprove(cdai, _want);
            ICToken(cdai).mint(_want);
        }
    }
}
