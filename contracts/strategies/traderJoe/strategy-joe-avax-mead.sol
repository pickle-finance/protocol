// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxMeadLp is StrategyJoeRushFarmBase {

    uint256 public avax_mead_poolId = ;

    address public joe_avax_mead_lp = ;
    address public mead = 0x245C2591403e182e41d7A851eab53B01854844CE;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_mead_poolId,
            joe_avax_mead_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}


     function _takeFeeMeadToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = mead;
        path[1] = wavax;
        path[2] = snob;
        IERC20(mead).safeApprove(joeRouter, 0);
        IERC20(mead).safeApprove(joeRouter, _keep);
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
        
        uint256 _mead = IERC20(mead).balanceOf(address(this));   //get balance of Mead Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_mead > 0) {
            uint256 _keep2 = _mead.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeMeadToSnob(_keep2);
            }
            
            _mead = IERC20(mead).balanceOf(address(this));
          
        }

        //In the case of Mead Rewards, swap mead for wavax
        if(_mead > 0){
            IERC20(mead).safeApprove(joeRouter, 0);
            IERC20(mead).safeApprove(joeRouter, _mead.div(2));   
            _swapTraderJoe(mead, wavax, _mead.div(2));
        }

        //in the case of Avax Rewards, swap wavax for mead
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, mead, _wavax.div(2)); 
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
            _swapTraderJoe(joe, mead, _joe.div(2));
        }

        // Adds in liquidity for AVAX/mead
        _wavax = IERC20(wavax).balanceOf(address(this));
        _mead = IERC20(mead).balanceOf(address(this));

        if (_wavax > 0 && _mead > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(mead).safeApprove(joeRouter, 0);
            IERC20(mead).safeApprove(joeRouter, _mead);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                mead,
                _wavax,
                _mead,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _mead = IERC20(mead).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_mead > 0){
                IERC20(mead).safeTransfer(
                    IController(controller).treasury(),
                    _mead
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMeadLp";
    }
}