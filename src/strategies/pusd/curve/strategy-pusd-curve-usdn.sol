// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-pusd-base.sol";

import "../../../interfaces/curve.sol";
import "hardhat/console.sol";

// Base contract for Curve based staking contract interfaces

contract StrategyPusdCrvUsdn is StrategyPusdBase {
    // curve dao
    address public gauge = 0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4;
    address public curve = 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public curveDepositUSDN = 0x094d12e5b541784701FD8d65F11fc0598FBC6332;
    address public crvUSDN = 0x4f3E8F405CF5aFC05D68142F3783bDfE13811522;

    // rewards
    address public crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // How much CRV tokens to keep
    uint256 public keepCRV = 0;
    uint256 public keepCRVMax = 10000;

    address[] public uniswap_CRV2DAI;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPusdBase(_governance, _strategist, _controller, _timelock)
    {
        underlying = crvUSDN;
        uniswap_CRV2DAI = [crv, weth, dai];
    }

    // **** Getters ****

    function getName() external override pure returns (string memory) {
        return "StrategyPusdCrvUsdn";
    }

    function balanceOfPool() public override view returns (uint256) {
        uint256 _underlying = ICurveGauge(gauge).balanceOf(address(this));
        uint256 _want;
        if (_underlying > 0) {
            _want = ICurveDeposit(curveDepositUSDN).calc_withdraw_one_coin(_underlying, curveIndex);
        }

        return _want;
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_reward(address(this), address(crv));
    }

    function _wantToUnderlying() internal override returns (uint256) {
        uint256 _want = IERC20(want).balanceOf(address(this));

        if (_want > 0) {
            IERC20(want).safeApprove(curveDepositUSDN, 0);
            IERC20(want).safeApprove(curveDepositUSDN, _want);

            ICurveDeposit(curveDepositUSDN).add_liquidity([0, _want, 0, 0], 0);
            // now we have usdnCRV
        }
    }

    function _underlyingToWant() internal override returns (uint256) {
        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        
        if (_underlying > 0) {
            IERC20(underlying).safeApprove(curveDepositUSDN, 0);
            IERC20(underlying).safeApprove(curveDepositUSDN, _underlying);
            
            ICurveDeposit(curveDepositUSDN).remove_liquidity_one_coin(_underlying, curveIndex, 0);
        }
    }

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutation functions ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            _wantToUnderlying();

            uint256 _underlying = IERC20(underlying).balanceOf(address(this));

            IERC20(underlying).safeApprove(gauge, 0);
            IERC20(underlying).safeApprove(gauge, _underlying);
            ICurveGauge(gauge).deposit(_underlying);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _underlying = ICurveGauge(gauge).balanceOf(address(this));
        uint256 _wantInGauge = balanceOfPool();
        uint256 _underlyingToWithdraw = _underlying.mul(_amount).div(_wantInGauge);

        if (_underlyingToWithdraw > _underlying) {
            _underlyingToWithdraw = _underlying;
        }

        if (_underlyingToWithdraw > 0) {
            ICurveGauge(gauge).withdraw(_underlyingToWithdraw);
        }

        uint256 _wantBefore = IERC20(want).balanceOf(address(this));
        _underlyingToWant();
        uint256 _wantAfter = IERC20(want).balanceOf(address(this));
        return _wantAfter.sub(_wantBefore);
    }

    function harvest() public override onlyBenevolent {
        ICurveMintr(mintr).mint(address(gauge));

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);

        if (_keepCRV > 0) {
            IERC20(crv).safeTransfer(
                IController(controller).treasury(),
                _keepCRV
            );
        }

        _crv = _crv.sub(_keepCRV);
        _swapUniswapWithPath(uniswap_CRV2DAI, _crv);
    }
}
