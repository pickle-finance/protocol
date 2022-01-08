// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";

contract StrategyBalancerBalWethLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;

    address public bal = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;
    address public token0 = bal;
    address public token1 = weth;

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0xcC65A812ce382aB909a11E434dbf75B34f1cc59D;
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
        return "StrategyBalancerBalWethLp";
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

        // allow Balancer to sell our reward
        IERC20(bal).safeApprove(vault, 0);
        IERC20(bal).safeApprove(vault, _balBalance);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = _balBalance;
        amountsIn[1] = 0;
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
