// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-xjoe-farm-base.sol";

contract StrategyJoexJoe is StrategyxJoeFarmBase {

    uint256 public avax_snob_poolId = 8;

    address public joe_avax_snob_lp = 0x8fB5bD3aC8eFD05DACae82F512dD03e14aAdAb73;
    address public snob = 0xC38f41A296A4493Ff429F1238e030924A1542e50;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyxJoeFarmBase(
            avax_snob_poolId,
            joe_avax_snob_lp,
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
            uint256 _keepJOE = _joe.mul(keepJOE).div(keepJOEMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE);
            IERC20(joe).safeApprove(joeBar, 0);
            IERC20(joe).safeApprove(joeBar, _joe.sub(_keepJOE));

			//Deposit Harvested Joe into xJoe
			IJoeBar(joeBar).enter(_amount);
            
        }
   
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxSnobLp";
    }
}
