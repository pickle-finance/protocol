// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenUsdcDaiMaiLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address public constant usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address[] public pool_tokens = [
        usdc,
        0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E, // dai
        0xfB98B335551a418cD0737375a2ea0ded62Ea213b  // mai/miMatic
    ];

    uint256 public masterchef_poolid = 16;
    bytes32 public vault_poolid = 0x2c580c6f08044d6dfaca8976a66c8fadddbd9901000000000000000000000038;
    address public lp_token = 0x2C580C6F08044D6dfACA8976a66C8fAddDBD9901;

    mapping(address => address[]) public swapRoutes;

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
    {
        sushiRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        IERC20(wftm).approve(sushiRouter, uint256(-1));
        swapRoutes[usdc] = [wftm, usdc];
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBeethovenUsdcDaiMaiLp";
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

        // Swap WFTM for USDC
        uint256 _wftm = IERC20(wftm).balanceOf(address(this));
        _swapSushiswapWithPath(swapRoutes[usdc], _wftm);

        // approve USDC spending
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).safeApprove(vault, 0);
        IERC20(usdc).safeApprove(vault, _usdc);

        IAsset[] memory assets = new IAsset[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            assets[_i] = IAsset(tokens[_i]);
        }

        IBVault.JoinKind joinKind = IBVault
        .JoinKind
        .EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](tokens.length);
        for (uint8 _i = 0; _i < tokens.length; _i++) {
            if (tokens[_i] == usdc) {
                amountsIn[_i] = _usdc;
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

        // deposit USDC into BeethovenX pool
        IBVault(vault).joinPool(vaultPoolId, address(this), address(this), request);

        // deposit pool token into BeethovenX masterchef
        _distributePerformanceFeesAndDeposit();
    }
}
