// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../lib/balancer-vault.sol";
import "../../../interfaces/staking-rewards.sol";

contract StrategyBalancerVstaEthLp is StrategyBase {
    // Token addresses
    address public vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public poolId =
        0xc61ff48f94d801c1ceface0289085197b5ec44f000020000000000000000004d;

    address public vsta = 0xa684cd057951541187f288294a1e1C2646aA2d24;

    // pool deposit fee
    uint256 public depositFee = 0;

    address _lp = 0xC61ff48f94D801c1ceFaCE0289085197B5ec44F0;

    address public rewards = 0x65207da01293C692a37f59D1D9b1624F0f21177c;

    // How much VSTA tokens to keep?
    uint256 public keepVSTA = 2000;
    uint256 public constant keepVSTAMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        IERC20(vsta).safeApprove(vault, uint256(-1));
        IERC20(weth).safeApprove(vault, uint256(-1));
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBalancerVstaEthLp";
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(rewards).balances(address(this));
    }

    function getHarvestable() external view virtual returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function setKeepVSTA(uint256 _keepVSTA) external {
        require(msg.sender == timelock, "!timelock");
        keepVSTA = _keepVSTA;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override {
        IStakingRewards(rewards).getReward();
        uint256 _vsta = IERC20(vsta).balanceOf(address(this));
        if (_vsta == 0) {
            return;
        }

        uint256 _keepVSTA = _vsta.mul(keepVSTA).div(keepVSTAMax);
        IERC20(vsta).safeTransfer(
            IController(controller).treasury(),
            _keepVSTA
        );
        _vsta = IERC20(vsta).balanceOf(address(this));

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(0));
        assets[1] = IAsset(vsta);

        IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = 0;
        amountsIn[1] = _vsta;

        bytes memory userData = abi.encode(joinKind, amountsIn, 1);

        IBVault.JoinPoolRequest memory request = IBVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        IBVault(vault).joinPool(poolId, address(this), address(this), request);
        deposit();
    }
}
