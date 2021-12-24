// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";

contract StrategyBalancerPickleWethLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0xc2f082d33b5b8ef3a7e3de30da54efd3114512ac000200000000000000000017;

    bytes32 public balEthPoolId =
        0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;

    address public bal = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;
    address public pickle = 0x965772e0E9c84b6f359c8597C891108DcF1c5B1A;
    address public token0 = weth;
    address public token1 = pickle;

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0xc2F082d33b5B8eF3A7E3de30da54EFd3114512aC;
    address balDistributor = 0x6bd0B17713aaa29A2d7c9A39dDc120114f9fD809;

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
        return "StrategyBalancerPickleWethLp";
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

    function claimBal(
        uint256 _week,
        uint256 _claim,
        bytes32[] memory merkleProof
    ) public {
        IMerkleRedeem(balDistributor).claimWeek(
            address(this),
            _week,
            _claim,
            merkleProof
        );
    }

    function setDistributor(address _distributor) external {
        require(msg.sender == governance, "not authorized");
        balDistributor = _distributor;
    }

    function harvest() public override onlyBenevolent {
        uint256 _balBalance = IERC20(bal).balanceOf(address(this));
        uint256 _pickleBalance = IERC20(pickle).balanceOf(address(this));

        if (_balBalance == 0 && _pickleBalance == 0) {
            return;
        }

        if (_balBalance > 0) {
            // allow Balancer to sell our reward
            IERC20(bal).safeApprove(vault, 0);
            IERC20(bal).safeApprove(vault, _balBalance);

            // Swap BAL for WETH
            IBVault.SingleSwap memory balSwapParams = IBVault.SingleSwap({
                poolId: balEthPoolId,
                kind: IBVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(bal),
                assetOut: IAsset(weth),
                amount: _balBalance,
                userData: "0x"
            });
            IBVault.FundManagement memory balFunds = IBVault.FundManagement({
                sender: address(this),
                recipient: payable(address(this)),
                fromInternalBalance: false,
                toInternalBalance: false
            });
            IBVault(vault).swap(balSwapParams, balFunds, 1, now + 60);
        }

        // approve WETH spending
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        IERC20(weth).safeApprove(vault, 0);
        IERC20(weth).safeApprove(vault, _weth);

        // approve PICKLE spending
        IERC20(pickle).safeApprove(vault, 0);
        IERC20(pickle).safeApprove(vault, _pickleBalance);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = _weth;
        amountsIn[1] = _pickleBalance;
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
