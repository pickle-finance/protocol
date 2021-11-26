// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxMeltLp is StrategyJoeRushFarmBase {

    uint256 public avax_melt_poolId = 19;

    address public joe_avax_melt_lp = 0x2923a62b2531EC744ca0C1e61dfFab1Ad9369FeB;
    address public melt = 0x47EB6F7525C1aA999FBC9ee92715F5231eB1241D;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_melt_poolId,
            joe_avax_melt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}


     function _takeFeeMeltToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = melt;
        path[1] = wavax;
        path[2] = snob;
        IERC20(melt).safeApprove(joeRouter, 0);
        IERC20(melt).safeApprove(joeRouter, _keep);
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
        
        uint256 _melt = IERC20(melt).balanceOf(address(this));   //get balance of MELT Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_melt > 0) {
            uint256 _keep2 = _melt.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeMeltToSnob(_keep2);
            }
            
            _melt = IERC20(melt).balanceOf(address(this));
          
        }

        // In the case that there are melt and Avax Rewards swap half melt for wavax and  1/2 wavax for melt using prior balances
        if (_melt > 0 && _wavax > 0){
            IERC20(melt).safeApprove(joeRouter, 0);
            IERC20(melt).safeApprove(joeRouter, _melt.div(2));   
            _swapTraderJoe(melt, wavax, _melt.div(2));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, melt, _wavax.div(2)); 
        }

        // In the case of Melt Rewards and no Avax rewards, swap melt for wavax
        if(_melt > 0 && _wavax ==0){
            IERC20(melt).safeApprove(joeRouter, 0);
            IERC20(melt).safeApprove(joeRouter, _melt.div(2));   
            _swapTraderJoe(melt, wavax, _melt.div(2));
        }

        // In the case of Avax Rewards and no melt rewards, swap wavax for melt
        if(_wavax > 0 && _melt ==0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, melt, _wavax.div(2)); 
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
            _swapTraderJoe(joe, melt, _joe.div(2));
        }

        // Adds in liquidity for AVAX/MELT
        _wavax = IERC20(wavax).balanceOf(address(this));
        _melt = IERC20(melt).balanceOf(address(this));

        if (_wavax > 0 && _melt > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(melt).safeApprove(joeRouter, 0);
            IERC20(melt).safeApprove(joeRouter, _melt);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                melt,
                _wavax,
                _melt,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _melt = IERC20(melt).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_melt > 0){
                IERC20(melt).safeTransfer(
                    IController(controller).treasury(),
                    _melt
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMeltLp";
    }
}
