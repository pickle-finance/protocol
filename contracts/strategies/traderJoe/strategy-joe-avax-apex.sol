// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxApexLp is StrategyJoeRushFarmBase {
    uint256 public avax_apex_poolId = 6;

    address public joe_avax_apex_lp = 0x824Ca83923990b91836ea927c14C1fb1B1790B08;
    address public apex = 0xd039C9079ca7F2a87D632A9C0d7cEa0137bAcFB5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_apex_poolId,
            joe_avax_apex_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

   function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        
        //Take Avax Rewards    
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            uint256 _amount2 = _wavax.sub(_keep2).div(2);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }

            //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _amount2);   
            _swapTraderJoe(wavax, apex, _amount2);
        }


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
            _swapTraderJoe(joe, apex, _amount);
        }

        // Swap half WAVAX for GB: 1% Reflective
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.mul(100).div(196));
            _swapTraderJoe(wavax, apex, _wavax.mul(100).div(196));
        }


        // Adds in liquidity for AVAX/apex
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _apex = IERC20(apex).balanceOf(address(this));
        if (_wavax > 0 && _apex > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(apex).safeApprove(joeRouter, 0);
            IERC20(apex).safeApprove(joeRouter, _apex);

        
            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                apex,
                _wavax,
                _apex,
                0,
                0,
                address(this),
                now + 60
            );



             // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            if (_wavax > 0) {
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            _apex = IERC20(apex).balanceOf(address(this));
            if (_apex > 0) {
                IERC20(apex).safeTransfer(
                    IController(controller).treasury(),
                    _apex
                );

            }

        }

        _distributePerformanceFeesAndDeposit();
    }
    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxApexLp";
    }
}