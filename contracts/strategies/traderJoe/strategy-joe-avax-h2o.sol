// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxH2O is StrategyJoeRushFarmBase {

    uint256 public avax_h2o_poolId = 27;

    address public joe_avax_h2o_lp = 0x9615a11eAA912eAE869E9c1097df263Fc3E105F3;
    address public h2o = 0x026187BdbC6b751003517bcb30Ac7817D5B766f8;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_h2o_poolId,
            joe_avax_h2o_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeH2OToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = h2o;
        path[1] = wavax;
        path[2] = snob;
        IERC20(h2o).safeApprove(joeRouter, 0);
        IERC20(h2o).safeApprove(joeRouter, _keep);
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
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _h2o = IERC20(h2o).balanceOf(address(this));   //get balance of H2O Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_h2o > 0) {
            uint256 _keep2 = _h2o.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeH2OToSnob(_keep2);
            }
            
            _h2o = IERC20(h2o).balanceOf(address(this));
          
        }

        // In the case of H2O Rewards, swap H2O for wavax
        if(_h2o > 0){
            IERC20(h2o).safeApprove(joeRouter, 0);
            IERC20(h2o).safeApprove(joeRouter, _h2o.div(2));   
            _swapTraderJoe(h2o, wavax, _h2o.div(2));
        }

        // In the case of Avax Rewards, swap wavax for H2O
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, h2o, _wavax.div(2)); 
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
            _swapTraderJoe(joe, h2o, _joe.div(2));
        }

        // Adds in liquidity for AVAX/H2O
        _wavax = IERC20(wavax).balanceOf(address(this));
        _h2o = IERC20(h2o).balanceOf(address(this));

        if (_wavax > 0 && _h2o > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(h2o).safeApprove(joeRouter, 0);
            IERC20(h2o).safeApprove(joeRouter, _h2o);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                h2o,
                _wavax,
                _h2o,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _h2o = IERC20(h2o).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_h2o > 0){
                IERC20(h2o).safeTransfer(
                    IController(controller).treasury(),
                    _h2o
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
        return "StrategyJoeAvaxH2O";
    }
}