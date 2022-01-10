// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxPln is StrategyJoeRushFarmBase {

    uint256 public avax_pln_poolId = 31;

    address public joe_avax_pln_lp = 0x829A9F8894Ef17F1523EC87a9f8e5e0CF5DC2003;
    address public pln = 0x7b2B702706D9b361dfE3f00bD138C0CFDA7FB2Cf;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_pln_poolId,
            joe_avax_pln_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeImeToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = pln;
        path[1] = wavax;
        path[2] = snob;
        IERC20(pln).safeApprove(joeRouter, 0);
        IERC20(pln).safeApprove(joeRouter, _keep);
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
        
        uint256 _pln = IERC20(pln).balanceOf(address(this));   //get balance of PLN Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_pln > 0) {
            uint256 _keep2 = _pln.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeImeToSnob(_keep2);
            }
            
            _pln = IERC20(pln).balanceOf(address(this));
          
        }

        // In the case of PLN Rewards, swap PLN for WAVAX
        if(_pln > 0){
            IERC20(pln).safeApprove(joeRouter, 0);
            IERC20(pln).safeApprove(joeRouter, _pln.div(2));   
            _swapTraderJoe(pln, wavax, _pln.div(2));
        }

        // In the case of AVAX Rewards, swap WAVAX for PLN
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, pln, _wavax.div(2)); 
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
            _swapTraderJoe(joe, pln, _joe.div(2));
        }

        // Adds in liquidity for AVAX/PLN
        _wavax = IERC20(wavax).balanceOf(address(this));
        _pln = IERC20(pln).balanceOf(address(this));

        if (_wavax > 0 && _pln > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(pln).safeApprove(joeRouter, 0);
            IERC20(pln).safeApprove(joeRouter, _pln);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                pln,
                _wavax,
                _pln,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _pln = IERC20(pln).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_pln > 0){
                IERC20(pln).safeTransfer(
                    IController(controller).treasury(),
                    _pln
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
        return "StrategyJoeAvaxPln";
    }
}