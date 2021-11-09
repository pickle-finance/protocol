// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxOhLp is StrategyJoeRushFarmBase {
    uint256 public avax_oh_poolId = 4;

    address public joe_avax_oh_lp = 0x361B625c074c736ef2d959e983b4478aA23a5d19;
    address public oh = 0x937E077aBaEA52d3abf879c9b9d3f2eBd15BAA21;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_oh_poolId,
            joe_avax_oh_lp,
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

            //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, oh, _wavax.div(2));
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

            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, oh, _joe.div(2));
        }

        // Adds in liquidity for AVAX/OH
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _oh = IERC20(oh).balanceOf(address(this));

        if (_wavax > 0 && _oh > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(oh).safeApprove(joeRouter, 0);
            IERC20(oh).safeApprove(joeRouter, _oh);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                oh,
                _wavax,
                _oh,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _oh = IERC20(oh).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_oh > 0){
                IERC20(oh).safeTransfer(
                    IController(controller).treasury(),
                    _oh
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****
    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxOhLp";
    }
}