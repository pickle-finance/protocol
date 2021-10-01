// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxBnbLp is StrategyJoeFarmBase {
    uint256 public avax_bnb_poolId = 52;

    address public joe_avax_bnb_lp = 0xeb8eB6300c53C3AddBb7382Ff6c6FbC4165B0742;
    address public bnb = 0x264c1383EA520f73dd837F915ef3a732e204a493;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_bnb_poolId,
            joe_avax_bnb_lp,
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
            uint256 _keepJOE = _joe.mul(keep).div(keepMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, bnb, _amount);
        }

        // Adds in liquidity for AVAX/BNB
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _bnb = IERC20(bnb).balanceOf(address(this));

        if (_wavax > 0 && _bnb > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(bnb).safeApprove(joeRouter, 0);
            IERC20(bnb).safeApprove(joeRouter, _bnb);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                bnb,
                _wavax,
                _bnb,
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
            IERC20(bnb).safeTransfer(
                IController(controller).treasury(),
                IERC20(bnb).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxBnbLp";
    }
}
