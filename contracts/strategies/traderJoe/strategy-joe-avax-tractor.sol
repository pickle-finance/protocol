// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxTractorLp is StrategyJoeRushFarmBase {
    uint256 public avax_tractor_poolId = 7;

    address public joe_avax_tractor_lp = 0x601e0f63bE88A52b79DbaC667d6b4A167CE39113;
    address public tractor = 0x542fA0B261503333B90fE60c78F2BeeD16b7b7fD;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_tractor_poolId,
            joe_avax_tractor_lp,
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
            _swapTraderJoe(wavax, tractor, _amount2);
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
            _swapTraderJoe(joe, tractor, _amount);
        }

        // Swap half WAVAX for GB: 1% Reflective
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.mul(100).div(197));
            _swapTraderJoe(wavax, tractor, _wavax.mul(100).div(197));
        }


        // Adds in liquidity for AVAX/tractor
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _tractor = IERC20(tractor).balanceOf(address(this));
        if (_wavax > 0 && _tractor > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(tractor).safeApprove(joeRouter, 0);
            IERC20(tractor).safeApprove(joeRouter, _tractor);

        
            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                tractor,
                _wavax,
                _tractor,
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
            _tractor = IERC20(tractor).balanceOf(address(this));
            if (_tractor > 0) {
                IERC20(tractor).safeTransfer(
                    IController(controller).treasury(),
                    _tractor
                );

            }

        }

        _distributePerformanceFeesAndDeposit();
    }
    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxTractorLp";
    }
}