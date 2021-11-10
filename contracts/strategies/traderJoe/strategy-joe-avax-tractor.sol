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

        // Collects Rewards tokens (JOE & AVAX)
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        //Take Avax Rewards    
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            // convert Avax Rewards
            // TRACTOR: 3% Reflective 1% Burn
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.mul(100).div(196));   
            _swapTraderJoe(wavax, tractor, _wavax.mul(100).div(196));
        }
        
        // Take Joe Rewards
        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            // TRACTOR: 3% Reflective 1% Burn
            _swapTraderJoe(joe, wavax, _joe.mul(96).div(196));
            _swapTraderJoe(joe, tractor, _joe.mul(100).div(196));
        }

        // Adds in liquidity for AVAX/TRACTOR
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
            _tractor = IERC20(tractor).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_tractor > 0){
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