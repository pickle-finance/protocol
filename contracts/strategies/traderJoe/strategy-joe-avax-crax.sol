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


     function _takeFeeCraxToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = crax;
        path[1] = wavax;
        path[2] = snob;
        IERC20(crax).safeApprove(pangolinRouter, 0);
        IERC20(crax).safeApprove(pangolinRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native Avax
        if (_avax > 0) {                                    // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _crax = IERC20(crax).balanceOf(address(this));   //get balance of CRA Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_crax > 0) {
            uint256 _keep2 = _crax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeCraxToSnob(_keep2);
            }
            
            _crax = IERC20(crax).balanceOf(address(this));
          
        }

        //in the case that there are crax and Avax Rewards swap half crax for wavax and  1/2 wavax for crax using prior balances
        if (_crax > 0 && _wavax > 0){
            IERC20(crax).safeApprove(joeRouter, 0);
            IERC20(crax).safeApprove(joeRouter, _crax.div(2));   
            _swapTraderJoe(crax, wavax, _crax.div(2));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, crax, _wavax.div(2)); 
        }

        //In the case of Crax Rewards and no Avax rewards, swap crax for wavax
        if(_crax > 0 && _wavax ==0){
            IERC20(crax).safeApprove(joeRouter, 0);
            IERC20(crax).safeApprove(joeRouter, _crax.div(2));   
            _swapTraderJoe(crax, wavax, _crax.div(2));
        }

        //in the case of Avax Rewards and no crax rewards, swap wavax for crax
        if(_wavax > 0 && _crax ==0){
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
        _crax = IERC20(crax).balanceOf(address(this));

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
