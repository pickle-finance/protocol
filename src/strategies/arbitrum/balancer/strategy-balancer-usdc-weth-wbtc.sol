// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";

contract StrategyBalancerWbtcWethUsdcLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002;

    bytes32 public balEthPool =
        0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;

    address public bal = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;
    address public token0 = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; // wbtc
    address public token1 = weth;
    address public token2 = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // usdc

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0x64541216bAFFFEec8ea535BB71Fbc927831d0595;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyBalancerWbtcWethUsdcLp";
    }

    function balanceOfPool() public view override returns (uint256) {
        return 0;
    }

    function getHarvestable() external view virtual returns (uint256) {
        return IERC20(bal).balanceOf(address(this));
    }

    // **** Setters ****

    function deposit() public override {}

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        uint256 _rewardBalance = IERC20(bal).balanceOf(address(this));

        if (_rewardBalance == 0) {
            return;
        }

        // allow Balancer to sell our reward
        IERC20(bal).safeApprove(vault, 0);
        IERC20(bal).safeApprove(vault, _rewardBalance);

        // Swap BAL for WETH
        IBVault.SingleSwap memory swapParams = IBVault.SingleSwap({
            poolId: balEthPool,
            kind: IBVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(bal),
            assetOut: IAsset(weth),
            amount: _rewardBalance,
            userData: "0x"
        });
        IBVault.FundManagement memory funds = IBVault.FundManagement({
            sender: address(this),
            recipient: payable(address(this)),
            fromInternalBalance: false,
            toInternalBalance: false
        });
        IBVault(vault).swap(swapParams, funds, 1, now + 60);

        // approve WETH spending
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        IERC20(weth).safeApprove(vault, 0);
        IERC20(weth).safeApprove(vault, _weth);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);
        assets[2] = IAsset(token2);

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](3);
        amountsIn[0] = 0;
        amountsIn[1] = _weth;
        amountsIn[2] = 0;
        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBVault.JoinPoolRequest memory request = IBVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        uint256 _before = IERC20(want).balanceOf(address(this));

        IBVault(vault).joinPool(poolId, address(this), address(this), request);

        uint256 _after = IERC20(want).balanceOf(address(this));
        uint256 _amount = _after.sub(_before);
        _distributePerformanceFeesBasedAmountAndDeposit(_amount);
    }
}
