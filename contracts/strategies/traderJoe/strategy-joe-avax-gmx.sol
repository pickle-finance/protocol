// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxGmx is StrategyJoeRushFarmBase {

    uint256 public avax_gmx_poolId = 43;

    address public joe_avax_gmx_lp = 0x0c91a070f862666bBcce281346BE45766d874D98;
    address public gmx = 0x62edc0692BD897D2295872a9FFCac5425011c661;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_gmx_poolId,
            joe_avax_gmx_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  // get balance of WAVAX
        uint256 _gmx = IERC20(gmx).balanceOf(address(this));    // get balance of GMX 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_gmx > 0) {
            uint256 _keep = _gmx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, gmx);
            }
            
            _gmx = IERC20(gmx).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap half WAVAX for GMX
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, gmx, _wavax.div(2));
        }

        // In the case of GMX Rewards, swap half GMX for WAVAX
        if(_gmx > 0){
            IERC20(gmx).safeApprove(joeRouter, 0);
            IERC20(gmx).safeApprove(joeRouter, _gmx.div(2));   
            _swapTraderJoe(gmx, wavax, _gmx.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and GMX        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, gmx, _joe.div(2));
        }

        // Adds in liquidity for AVAX/GMX
        _wavax = IERC20(wavax).balanceOf(address(this));
        _gmx = IERC20(gmx).balanceOf(address(this));

        if (_wavax > 0 && _gmx > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(gmx).safeApprove(joeRouter, 0);
            IERC20(gmx).safeApprove(joeRouter, _gmx);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                gmx,
                _wavax,
                _gmx,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _gmx = IERC20(gmx).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_gmx > 0){
                IERC20(gmx).safeTransfer(
                    IController(controller).treasury(),
                    _gmx
                );
            } 

            if (_joe > 0){
                IERC20(joe).transfer(
                    IController(controller).treasury(),
                    _joe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxGmx";
    }
}