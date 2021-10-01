// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../../interfaces/dodo.sol";

contract StrategyDodoHndEthLp is StrategyBase {
    // Token addresses
    address public constant dodo = 0x69Eb4FA4a2fbd498C257C57Ea8b7655a2559A581;
    address public constant hnd = 0x10010078a54396F62c96dF8532dc2B4847d47ED3;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public constant rewards =
        0x06633cd8E46C3048621A517D6bb5f0A84b4919c6;
    address public constant dodo_hnd_eth_lp =
        0x65E17c52128396443d4A9A61EaCf0970F05F8a20;
    address public constant dodoSwap =
        0x88CBf433471A0CD8240D2a12354362988b4593E5;
    address public constant dodoMultiSwap =
        0x3B6067D4CAa8A14c63fdBE6318F27A0bBc9F9237;

    address public constant dodoUsdcPair =
        0x6a58c68FF5C4e4D90EB6561449CC74A64F818dA5;
    address public constant usdcEthPair =
        0x905dfCD5649217c42684f23958568e533C711Aa3;

    address[] public dodoEthAdapters;
    address[] public dodoEthPairs;
    address[] public dodoEthSwapTo;

    address[] public hndEthRoute = [dodo_hnd_eth_lp];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            dodo_hnd_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        dodoEthAdapters = new address[](2);
        dodoEthPairs = new address[](2);
        dodoEthSwapTo = new address[](3);

        dodoEthAdapters = [
            0x8aB2D334cE64B50BE9Ab04184f7ccBa2A6bb6391,
            0x17eBC315760Bb47384224A5f3BF829222fbD3Aa7
        ];
        dodoEthPairs = [dodoUsdcPair, usdcEthPair];
        dodoEthSwapTo = [dodoUsdcPair, usdcEthPair, address(this)];
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
        uint256 _pendingHnd = IDodoMine(rewards).getPendingRewardByToken(
            address(this),
            hnd
        );
        // return IMiniChefV2(miniChef).pendingSushi(poolId, address(this));
        return (_pendingDodo, _pendingHnd);
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

        // Collects DODO tokens
        IDodoMine(rewards).claimAllRewards();
        uint256 _dodo = IERC20(dodo).balanceOf(address(this));
        if (_dodo > 0) {
            bytes[] memory moreInfos;
            IERC20(dodo).safeApprove(dodoMultiSwap, 0);
            IERC20(dodo).safeApprove(dodoMultiSwap, _dodo);
            IDodoMultiSwap(dodoMultiSwap).mixSwap(
                dodo,
                weth,
                _dodo,
                1,
                dodoEthAdapters,
                dodoEthPairs,
                dodoEthSwapTo,
                2,
                moreInfos,
                now + 60
            );
        }

        uint256 _hnd = IERC20(hnd).balanceOf((address(this)));
        address[] memory path = new address[](1);
        path[0] = dodo_hnd_eth_lp;

        if (_hnd > 0) {
            IERC20(hnd).safeApprove(dodoSwap, 0);
            IERC20(hnd).safeApprove(dodoSwap, _hnd);
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                hnd,
                weth,
                _hnd,
                1,
                path,
                1,
                false,
                now + 60
            );
        }

        // Swap half WETH for HND
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(dodoSwap, 0);
            IERC20(weth).safeApprove(dodoSwap, _weth.div(2));
            IDodoSwap(dodoSwap).dodoSwapV2TokenToToken(
                weth,
                hnd,
                _weth.div(2),
                1,
                path,
                0,
                false,
                now + 60
            );
        }

        // Adds in liquidity for WETH/HND
        _hnd = IERC20(hnd).balanceOf(address(this));
        _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0 && _hnd > 0) {
            IERC20(weth).safeApprove(dodoSwap, 0);
            IERC20(weth).safeApprove(dodoSwap, _weth);
            IERC20(hnd).safeApprove(dodoSwap, 0);
            IERC20(hnd).safeApprove(dodoSwap, _hnd);

            IDodoSwap(dodoSwap).addDVMLiquidity(
                dodo_hnd_eth_lp,
                _weth,
                _hnd,
                1,
                1,
                1,
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(hnd).safeTransfer(
                IController(controller).treasury(),
                IERC20(hnd).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyDodoHndEthLp";
    }
}
