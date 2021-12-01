// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxGroLp is StrategyJoeRushFarmBase {

    uint256 public avax_gro_poolId = 18;

    address public joe_avax_gro_lp = 0xB7a4Ca0c9B58a33B244C44a8Bf9833b0E7918429;
    address public gro = 0x72699ba15CC734F8db874fa9652c8DE12093F187;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_gro_poolId,
            joe_avax_gro_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native Avax
        if (_avax > 0) {                                    // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            // Convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, gro, _wavax.div(2));
        }

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
            _swapTraderJoe(joe, gro, _joe.div(2));
        }

        // Adds in liquidity for AVAX/GRO
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _gro = IERC20(gro).balanceOf(address(this));

        if (_wavax > 0 && _gro > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(gro).safeApprove(joeRouter, 0);
            IERC20(gro).safeApprove(joeRouter, _gro);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                gro,
                _wavax,
                _gro,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _gro = IERC20(gro).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_gro > 0){
                IERC20(gro).safeTransfer(
                    IController(controller).treasury(),
                    _gro
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxGroLp";
    }
}