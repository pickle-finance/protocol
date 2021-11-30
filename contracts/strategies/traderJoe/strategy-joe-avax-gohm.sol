// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxgOhmLp is StrategyJoeRushFarmBase {

    uint256 public avax_gohm_poolId = 21;

    address public joe_avax_gohm_lp = 0xB674f93952F02F2538214D4572Aa47F262e990Ff;
    address public gohm = 0x321E7092a180BB43555132ec53AaA65a5bF84251;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_gohm_poolId,
            joe_avax_gohm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}


     function _takeFeegOhmToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = gohm;
        path[1] = wavax;
        path[2] = snob;
        IERC20(gohm).safeApprove(joeRouter, 0);
        IERC20(gohm).safeApprove(joeRouter, _keep);
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
        
        uint256 _gohm = IERC20(gohm).balanceOf(address(this));   //get balance of Gohm Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_gohm > 0) {
            uint256 _keep2 = _gohm.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeegOhmToSnob(_keep2);
            }
            
            _gohm = IERC20(gohm).balanceOf(address(this));
          
        }

        //in the case that there are gohm and Avax Rewards swap half gohm for wavax and  1/2 wavax for gohm using prior balances
        if (_gohm > 0 && _wavax > 0){
            IERC20(gohm).safeApprove(joeRouter, 0);
            IERC20(gohm).safeApprove(joeRouter, _gohm.div(2));   
            _swapTraderJoe(gohm, wavax, _gohm.div(2));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, gohm, _wavax.div(2)); 
        }

        //In the case of Gohm Rewards and no Avax rewards, swap gohm for wavax
        if(_gohm > 0 && _wavax ==0){
            IERC20(gohm).safeApprove(joeRouter, 0);
            IERC20(gohm).safeApprove(joeRouter, _gohm.div(2));   
            _swapTraderJoe(gohm, wavax, _gohm.div(2));
        }

        //in the case of Avax Rewards and no gohm rewards, swap wavax for gohm
        if(_wavax > 0 && _gohm ==0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, gohm, _wavax.div(2)); 
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
            _swapTraderJoe(joe, gohm, _joe.div(2));
        }

        // Adds in liquidity for AVAX/GOHM
        _wavax = IERC20(wavax).balanceOf(address(this));
        _gohm = IERC20(gohm).balanceOf(address(this));

        if (_wavax > 0 && _gohm > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(gohm).safeApprove(joeRouter, 0);
            IERC20(gohm).safeApprove(joeRouter, _gohm);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                gohm,
                _wavax,
                _gohm,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _gohm = IERC20(gohm).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_gohm > 0){
                IERC20(gohm).safeTransfer(
                    IController(controller).treasury(),
                    _gohm
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxgOhmLp";
    }
}