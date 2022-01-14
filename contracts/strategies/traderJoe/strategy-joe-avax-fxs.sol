// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxFxs is StrategyJoeRushFarmBase {

    uint256 public avax_fxs_poolId = 38;

    address public joe_avax_fxs_lp = 0x53942Dcce5087f56cF1D68F4e017Ca3A793F59a2;
    address public fxs = 0x214DB107654fF987AD859F34125307783fC8e387;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_fxs_poolId,
            joe_avax_fxs_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeFxsToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = fxs;
        path[1] = wavax;
        path[2] = snob;
        IERC20(fxs).safeApprove(joeRouter, 0);
        IERC20(fxs).safeApprove(joeRouter, _keep);
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

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));   //get balance of FXS Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

         if (_fxs > 0) {
            uint256 _keep2 = _fxs.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeFxsToSnob(_keep2);
            }

            _fxs = IERC20(fxs).balanceOf(address(this));
        }

        // In the case of FXS Rewards, swap FXS for WAVAX
        if(_fxs > 0){
            IERC20(fxs).safeApprove(joeRouter, 0);
            IERC20(fxs).safeApprove(joeRouter, _fxs.div(2));   
            _swapTraderJoe(fxs, wavax, _fxs.div(2));
        }

        // In the case of WAVAX Rewards, swap WAVAX for FXS
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, fxs, _wavax.div(2)); 
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
            _swapTraderJoe(joe, fxs, _joe.div(2));
        }

        // Adds in liquidity for AVAX/FXS
        _wavax = IERC20(wavax).balanceOf(address(this));
        _fxs = IERC20(fxs).balanceOf(address(this));

        if (_wavax > 0 && _fxs > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(fxs).safeApprove(joeRouter, 0);
            IERC20(fxs).safeApprove(joeRouter, _fxs);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                fxs,
                _wavax,
                _fxs,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _fxs = IERC20(fxs).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_fxs > 0){
                IERC20(fxs).safeTransfer(
                    IController(controller).treasury(),
                    _fxs
                );
            }  
            if (_joe > 0){
                IERC20(joe).safeTransfer(
                    IController(controller).treasury(),
                    _joe
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxFxs";
    }
}