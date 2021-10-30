// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../interfaces/dodo.sol";

contract StrategyDodoMcbUsdcLp is StrategyBase {
    // Token addresses
    address public constant dodo = 0x69Eb4FA4a2fbd498C257C57Ea8b7655a2559A581;
    address public constant mcb = 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public constant rewards =
        0x98CEb851aF3d8627287885D56AEA863B848CeB6F;
    address public constant dodo_mcb_usdc_lp =
        0x34851Ea13Bde818B1EFE26D31377906b47C9BBE2;
    address public constant dodoSwap =
        0x88CBf433471A0CD8240D2a12354362988b4593E5;
    address public constant dodo_approve =
        0xA867241cDC8d3b0C07C85cC06F25a0cD3b5474d8;

    address public constant dodoUsdcPair =
        0x6a58c68FF5C4e4D90EB6561449CC74A64F818dA5;
    address public constant usdcEthPair =
        0x905dfCD5649217c42684f23958568e533C711Aa3;

    address[] public mcbUsdcRoute = [dodo_mcb_usdc_lp];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            dodo_mcb_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(dodo).approve(dodo_approve, uint256(-1));
        IERC20(mcb).approve(dodo_approve, uint256(-1));
        IERC20(usdc).approve(dodo_approve, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IDodoMine(rewards).balanceOf(address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingDodo = IDodoMine(rewards).getPendingRewardByToken(
            address(this),
            dodo
        );
        uint256 _pendingMcb = IDodoMine(rewards).getPendingRewardByToken(
            address(this),
            mcb
        );
        return (_pendingDodo, _pendingMcb);
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

        // Collects DODO tokens
        IDodoMine(rewards).claimAllRewards();
        uint256 _dodo = IERC20(dodo).balanceOf(address(this));
        if (_dodo > 0) {
            address[] memory path = new address[](1);
            path[0] = dodoUsdcPair;
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                dodo,
                usdc,
                _dodo,
                1,
                path,
                1,
                false,
                now + 60
            );
        }
        
        uint256 _mcb = IERC20(mcb).balanceOf(address(this));
        address[] memory path = new address[](1);
        path[0] = dodo_mcb_usdc_lp;

        if (_mcb > 0) {
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                mcb,
                usdc,
                _mcb,
                1,
                path,
                1,
                false,
                now + 60
            );
        }

        // Swap half USDC for MCB
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_usdc > 0) {
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                usdc,
                mcb,
                _usdc.div(2),
                1,
                path,
                0,
                false,
                now + 60
            );
        }

        // Adds in liquidity for MCB/USDC
        _mcb = IERC20(mcb).balanceOf(address(this));
        _usdc = IERC20(usdc).balanceOf(address(this));
        if (_mcb > 0 && _usdc > 0) {

            IDodoSwap(dodoSwap).addDVMLiquidity(
                dodo_mcb_usdc_lp,
                _mcb,
                _usdc,
                1,
                1,
                0,
                now + 60
            );

            // Donates DUST
            IERC20(mcb).transfer(
                IController(controller).treasury(),
                IERC20(mcb).balanceOf(address(this))
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
        return "StrategyDodoMcbUsdcLp";
    }
}
