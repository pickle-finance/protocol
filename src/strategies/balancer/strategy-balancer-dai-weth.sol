// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../lib/balancer-vault.sol";

contract StrategyBalancerDaiWethLp is StrategyBase {
    // Token Addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0x0b09dea16768f0799065c475be02919503cb2a3500020000000000000000001a;

    bytes32 public balEthPoolId =
        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    address public bal = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public token0 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai
    address public token1 = weth;

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0x0b09deA16768f0799065C475bE02919503cB2a35;
    address balDistributor = 0xd2EB7Bd802A7CA68d9AcD209bEc4E664A9abDD7b;

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
        return "StrategyBalancerDaiWethLp";
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

        if (_balBalance == 0) {
            return;
        }

        // approve BAL spending
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

        // approve WETH spending
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        IERC20(weth).safeApprove(vault, 0);
        IERC20(weth).safeApprove(vault, _weth);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = 0;
        amountsIn[1] = _weth;
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
