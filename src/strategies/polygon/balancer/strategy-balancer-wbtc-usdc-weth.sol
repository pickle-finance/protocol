// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";

contract StrategyBalancerWbtcUsdcWethLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0x03cd191f589d12b0582a99808cf19851e468e6b500010000000000000000000a;

    bytes32 public balEthPool =
        0xce66904b68f1f070332cbc631de7ee98b650b499000100000000000000000009;

    address public bal = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
    address public token0 = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; //wbtc
    address public token1 = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // usdc
    address public token2 = weth;

    // How much BAL tokens to keep?
    uint256 public keepReward = 0;
    uint256 public constant keepRewardMax = 10000;

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0x03cD191F589d12b0582a99808cf19851E468E6B5;

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
        return "StrategyBalancerWbtcUsdcWethLp";
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

    // **** Setters ****

    function setKeepReward(uint256 _keepReward) external {
        require(msg.sender == timelock, "!timelock");
        keepReward = _keepReward;
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
        IBVault.SingleSwap memory swapParams;
        swapParams.poolId = balEthPool;
        swapParams.kind = IBVault.SwapKind.GIVEN_IN;
        swapParams.assetIn = IAsset(bal);
        swapParams.assetOut = IAsset(weth);
        swapParams.amount = _rewardBalance;
        swapParams.userData = "0x";

        IBVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.recipient = payable(address(this));
        funds.toInternalBalance = false;

        IBVault(vault).swap(swapParams, funds, 1, now + 60);

        // add liquidity
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        IERC20(bal).safeApprove(vault, 0);
        IERC20(bal).safeApprove(vault, _weth);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);
        assets[2] = IAsset(token2);

        IBVault.JoinKind joinKind = IBVault
            .JoinKind
            .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](3);
        amountsIn[0] = 0;
        amountsIn[1] = 0;
        amountsIn[2] = 0;
        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBVault.JoinPoolRequest memory request;
        request.assets = assets;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        uint256 _before = IERC20(want).balanceOf(address(this));

        IBVault(vault).joinPool(poolId, address(this), address(this), request);

        uint256 _after = IERC20(want).balanceOf(address(this));
        uint256 _amount = _after.sub(_before);
        _distributePerformanceFeesBasedAmountAndDeposit(_amount);
    }
}
