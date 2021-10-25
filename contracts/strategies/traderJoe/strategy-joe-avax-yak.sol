// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxYakLp is StrategyJoeRushFarmBase {

    uint256 public avax_yak_poolId = 1;

    address public joe_avax_yak_lp = 0xb5c9e891AF3063004a441BA4FaB4cA3D6DEb5626;
    address public yak = 0x59414b3089ce2AF0010e7523Dea7E2b35d776ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_yak_poolId,
            joe_avax_yak_lp,
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
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

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
            _swapTraderJoe(joe, yak, _amount);
        }

        // Adds in liquidity for AVAX/YAK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _yak = IERC20(yak).balanceOf(address(this));

        if (_wavax > 0 && _yak > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(yak).safeApprove(joeRouter, 0);
            IERC20(yak).safeApprove(joeRouter, _yak);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                yak,
                _wavax,
                _yak,
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
            IERC20(yak).safeTransfer(
                IController(controller).treasury(),
                IERC20(yak).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxYakLp";
    }
}
