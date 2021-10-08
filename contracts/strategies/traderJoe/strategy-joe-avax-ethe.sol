// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxEthELp is StrategyJoeFarmBase {

    uint256 public avax_eth_poolId = 26;

    address public joe_avax_eth_lp = 0xFE15c2695F1F920da45C30AAE47d11dE51007AF9;
    address public eth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_eth_poolId,
            joe_avax_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV2).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            uint256 _amount = _joe.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, eth, _amount);
        }

        // Adds in liquidity for AVAX/ETH
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _eth = IERC20(eth).balanceOf(address(this));

        if (_wavax > 0 && _eth > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(eth).safeApprove(joeRouter, 0);
            IERC20(eth).safeApprove(joeRouter, _eth);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                eth,
                _wavax,
                _eth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(eth).safeTransfer(
                IController(controller).treasury(),
                IERC20(eth).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxEthELp";
    }
}
