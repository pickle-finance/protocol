// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../interfaces/dodo.sol";

contract StrategyDodoDodoUsdcLp is StrategyBase {
    // Token addresses
    address public constant dodo = 0x69Eb4FA4a2fbd498C257C57Ea8b7655a2559A581;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public constant rewards =
        0x38Dbb42C4972116c88E27edFacD2451cf1b14255;
    address public constant dodo_dodo_usdc_lp =
        0x6a58c68FF5C4e4D90EB6561449CC74A64F818dA5;
    address public constant dodoSwap =
        0x88CBf433471A0CD8240D2a12354362988b4593E5;
    address public constant dodo_approve =
        0xA867241cDC8d3b0C07C85cC06F25a0cD3b5474d8;

    address public constant dodoUsdcPair =
        0x6a58c68FF5C4e4D90EB6561449CC74A64F818dA5;

    address[] public dodoEthAdapters;
    address[] public dodoEthPairs;
    address[] public dodoEthSwapTo;

    address[] public dodoUsdcRoute = [dodo_dodo_usdc_lp];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            dodo_dodo_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(dodo).approve(dodo_approve, uint256(-1));
        IERC20(usdc).approve(dodo_approve, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IDodoMine(rewards).balanceOf(address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingDodo = IDodoMine(rewards).getPendingRewardByToken(
            address(this),
            dodo
        );
        return _pendingDodo;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IDodoMine(rewards).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IDodoMine(rewards).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects DODO token
        IDodoMine(rewards).claimAllRewards();

        // Swap half USDC for DODO
        uint256 _dodo = IERC20(dodo).balanceOf(address(this));
        if (_dodo > 0) {
            address[] memory path = new address[](1);
            path[0] = dodoUsdcPair;
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                dodo,
                usdc,
                _dodo.div(2),
                1,
                path,
                0,
                false,
                now + 60
            );
        }

        // Adds in liquidity for DODO/USDC
        _dodo = IERC20(dodo).balanceOf(address(this));
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_dodo > 0 && _usdc > 0) {

            IDodoSwap(dodoSwap).addDVMLiquidity(
                dodo_dodo_usdc_lp,
                _dodo,
                _usdc,
                1,
                1,
                0,
                now + 60
            );

            // Donates DUST
            IERC20(dodo).transfer(
                IController(controller).treasury(),
                IERC20(dodo).balanceOf(address(this))
            );
            IERC20(usdc).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdc).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyDodoDodoUsdcLp";
    }
}
