// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";

abstract contract StrategyBalancerWmaticUsdcWethBalLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    byte32 public poolId = 0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002;
    
    address public bal = 0x9a71012b13ca4d3d0cdc72a177df3ef03b0e76a3;
    address public token0 = wmatic;
    address public token1 = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // usdc
    address public token2 = weth;
    address public token3 = bal;

    // How much BAL tokens to keep?
    uint256 public keepReward = 0;
    uint256 public constant keepRewardMax = 10000;

    // pool deposit fee
    uint256 public depositFee = 0;

    mapping (address => address[]) public uniswapRoutes;

    address _lp = 0x0297e37f1873d2dab4487aa67cd56b58e2f27875;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
    }
    
    function balanceOfPool() public override view returns (uint256) {
        return 0;
    }

    function getHarvestable() external virtual view returns (uint256) {
        return IERC20(bal).balanceOf(address(this));
    }

    // **** Setters ****

    function deposit() public override {
    }

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
        if (_rewardBalance > 0) {
            // 10% is locked up for future gov
            uint256 _keepReward = _rewardBalance.mul(keepReward).div(keepRewardMax);
            IERC20(rewardToken).safeApprove(IController(controller).treasury(), 0);
            IERC20(rewardToken).safeApprove(IController(controller).treasury(), _keepReward);
            IERC20(rewardToken).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );
        }
        
        uint256 remainingRewardBalance = IERC20(rewardToken).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
          return;
        }
        
        // allow Uniswap to sell our reward
        IERC20(rewardToken).safeApprove(vault, 0);
        IERC20(rewardToken).safeApprove(vault, remainingRewardBalance);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);
        assets[2] = IAsset(token2);
        assets[3] = IAsset(token3);
        
        IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = 0;
        amountsIn[1] = 0;
        amountsIn[2] = 0;
        amountsIn[3] = remainingRewardBalance;
        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBVault.JoinPoolRequest memory request;
        request.assets = assets;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        IBVault(bVault()).joinPool(
          poolId(),
          address(this),
          address(this),
          request
        );
      }
}
