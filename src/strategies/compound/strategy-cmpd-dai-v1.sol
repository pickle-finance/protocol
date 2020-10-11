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
        address[] memory ctokens = new address[](2);
        ctokens[0] = cdai;
        ctokens[1] = cether;
        IComptroller(comptroller).enterMarkets(ctokens);
    }

    // Views

    function getName() external override pure returns (string memory) {
        return "StrategyCompoundDaiV1";
    }

    function balanceOfUnderlyingView() public view returns (uint256) {
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
            balanceOfUnderlyingView().sub(
                ICToken(cdai).borrowBalanceStored(address(this))
            );
    }

    // Use `callStatic` on this
    function getColRatio() public returns (uint256) {
        uint256 supplied = ICToken(cdai).balanceOfUnderlying(address(this));
        uint256 borrowed = ICToken(cdai).borrowBalanceCurrent(address(this));

        return supplied.mul(1e18).div(borrowed);
    }

    // Use `callStatic` on this
    function balanceOfPoolCurrent() public returns (uint256) {
        return
            ICToken(cdai).balanceOfUnderlying(address(this)).sub(
                ICToken(cdai).borrowBalanceCurrent(address(this))
            );
    }

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

    // Whats the idea target supply?
    function getTargetSupplyBalance() public returns (uint256) {
        // Balance w/o borrowed
        uint256 balance = balanceOfPoolCurrent();

        // Infinte geometric series
        uint256 leverage = getMaxLeverage();

        return balance.mul(leverage).div(1e18);
    }

    // Setters

    // TODO:
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {

    }

    function leverage() public payable {
        // dydx fee
        require(msg.value == 2, "!fee");

        // 1. Loan from DYDX
        // 2. Supply to ETH pool
        // 3. Borrow out <X> DAI
        // 4. Supply <X> DAI
        // 5. Take out ETH
        // 6. Repay DYDX
    }

    function deleverage() public payable {
        // dydx fee
        require(msg.value == 2, "!fee");
        
        // 1. Loan from dydx
        // 2. Supply to ETH Pool
        // 3. Draw out <X> DAI from supplied
        // 4. Repay <X> DAI from borrowed
        // 5. Take out ETH
        // 6. Repay Dydx
    }

    function harvest() public onlyBenevolent override {
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
