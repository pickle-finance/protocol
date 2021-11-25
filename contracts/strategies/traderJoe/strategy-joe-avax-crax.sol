// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxCraxLp is StrategyJoeRushFarmBase {

    uint256 public avax_crax_poolId = 13;

    address public joe_avax_crax_lp = 0x140CAc5f0e05cBEc857e65353839FddD0D8482C1;
    address public crax = 0xA32608e873F9DdEF944B24798db69d80Bbb4d1ed;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_crax_poolId,
            joe_avax_crax_lp,
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
            _swapTraderJoe(wavax, crax, _wavax.div(2));
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
            _swapTraderJoe(joe, crax, _joe.div(2));
        }

        // Adds in liquidity for AVAX/CRAX
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _crax = IERC20(crax).balanceOf(address(this));

        if (_wavax > 0 && _crax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(crax).safeApprove(joeRouter, 0);
            IERC20(crax).safeApprove(joeRouter, _crax);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                crax,
                _wavax,
                _crax,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _crax = IERC20(crax).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_crax > 0){
                IERC20(crax).safeTransfer(
                    IController(controller).treasury(),
                    _crax
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxCraxLp";
    }
}
