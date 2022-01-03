// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/beethovenx.sol";
import "../../lib/balancer-vault.sol";

abstract contract StrategyBeethovenxFarmBase is StrategyBase {
    // Token addresses
    address public constant beets = 0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e;
    address public constant vault = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;
    address public constant masterchef = 0x8166994d9ebBe5829EC86Bd81258149B87faCfd3;
    bytes32 public constant beetsFtmPoolId =
        0xcde5a11a4acb4ee4c805352cec57e236bdbc3837000200000000000000000019;
    
    // How much BEETS tokens to keep?
    uint256 public keepBEETS = 1000;
    uint256 public constant keepBEETSMax = 10000;

    // Pool tokens
    address[] public tokens;

    bytes32 public vaultPoolId;
    uint256 public masterchefPoolId;

    constructor(
        address[] memory _tokens,
        bytes32 _vaultPoolId,
        uint256 _masterchefPoolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        vaultPoolId = _vaultPoolId;
        masterchefPoolId = _masterchefPoolId;
        tokens = _tokens;

        IERC20(want).approve(masterchef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        // How much the strategy got staked in the masterchef
        (uint256 amount, ) = IBeethovenxMasterChef(masterchef).userInfo(
            masterchefPoolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingBeets = IBeethovenxMasterChef(masterchef).pendingBeets(
            masterchefPoolId,
            address(this)
        );

        return _pendingBeets;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            IBeethovenxMasterChef(masterchef).deposit(masterchefPoolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBeethovenxMasterChef(masterchef).withdrawAndHarvest(masterchefPoolId, _amount, address(this));
        return _amount;
    }

    // **** State Mutations ****

    function setKeepBEETS(uint256 _keepBEETS) external {
        require(msg.sender == timelock, "!timelock");
        keepBEETS = _keepBEETS;
    }

    function _harvestRewards() internal {
        // Collects BEETS tokens
        IBeethovenxMasterChef(masterchef).harvest(masterchefPoolId, address(this));
        uint256 _beets = IERC20(beets).balanceOf(address(this));
        uint256 _keepBEETS = _beets.mul(keepBEETS).div(keepBEETSMax);

        // Send performance fees to treasury
        IERC20(beets).safeTransfer(IController(controller).treasury(), _keepBEETS);
    }

    function harvest() public override {
        _harvestRewards();

        uint256 _rewardBalance = IERC20(beets).balanceOf(address(this));

        if (_rewardBalance == 0) {
            return;
        }

        // allow BeethovenX to sell our reward
        IERC20(beets).safeApprove(vault, 0);
        IERC20(beets).safeApprove(vault, _rewardBalance);

        // Swap BEETS for WFTM
        IBVault.SingleSwap memory swapParams = IBVault.SingleSwap({
            poolId: beetsFtmPoolId,
            kind: IBVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(beets),
            assetOut: IAsset(wftm),
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

        // approve WFTM spending
        uint256 _wftm = IERC20(wftm).balanceOf(address(this));
        IERC20(wftm).safeApprove(vault, 0);
        IERC20(wftm).safeApprove(vault, _wftm);

        IAsset[] memory assets = new IAsset[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            assets[_i] = IAsset(tokens[_i]);
        }

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            if (tokens[_i] == wftm) {
                amountsIn[_i] = _wftm;
            } else {
                amountsIn[_i] = 0;
            }
        }
        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBVault.JoinPoolRequest memory request = IBVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        // deposit WFTM into BeethovenX pool
        IBVault(vault).joinPool(vaultPoolId, address(this), address(this), request);

        // deposit pool token into BeethovenX masterchef
        _distributePerformanceFeesAndDeposit();
    }
}