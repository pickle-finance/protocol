// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

interface IBeetsBar {
    function enter(uint256 _amount) external;
    function leave(uint256 _shareOfFreshBeets) external;
}

contract StrategyBeethovenFtmBeetsLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address public fBeets = 0xfcef8a994209d6916EB2C86cDD2AFD60Aa6F54b1; // Fresh Beets contract
    address public bptBeetsFtm = 0xcdE5a11a4ACB4eE4c805352Cec57E236bdBC3837;    // fBeets underlying token
    address[] public pool_tokens = [
        wftm,
        beets
    ];

    uint256 public masterchef_poolid = 22;
    bytes32 public vault_poolid = 0xcde5a11a4acb4ee4c805352cec57e236bdbc3837000200000000000000000019;
    address public lp_token = fBeets;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBeethovenxFarmBase(
            pool_tokens, 
            vault_poolid, 
            masterchef_poolid, 
            lp_token, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyBeethovenFtmBeetsLp";
    }

    function harvest() public virtual override {
        _harvestRewards();

        uint256 _rewardBalance = IERC20(beets).balanceOf(address(this));

        if (_rewardBalance == 0) {
            return;
        }

        // approve BEETS spending
        IERC20(beets).safeApprove(vault, 0);
        IERC20(beets).safeApprove(vault, _rewardBalance);

        IAsset[] memory assets = new IAsset[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            assets[_i] = IAsset(tokens[_i]);
        }

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            if (tokens[_i] == beets) {
                amountsIn[_i] = _rewardBalance;
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

        // convert BPT-BEETS-FTM into fBeets
        uint256 _bpt = IERC20(bptBeetsFtm).balanceOf(address(this));
        IERC20(bptBeetsFtm).safeApprove(fBeets, 0);
        IERC20(bptBeetsFtm).safeApprove(fBeets, _bpt);
        IBeetsBar(fBeets).enter(_bpt);

        // deposit pool token into BeethovenX masterchef
        _distributePerformanceFeesAndDeposit();
    }
}
