// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/sAVAX Liquidity Pool with JOE and QI rewards
contract StrategyJoeAvaxSavax is StrategyJoeRushFarmBase {
    /// @dev LP and Token addresses
    uint256 public avax_savax_poolId = 51;
    address public joe_avax_savax_lp = 0x4b946c91C2B1a7d7C40FB3C130CdfBaf8389094d;
    
    address public savax = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address public qi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_savax_poolId,
            joe_avax_savax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice **** State Mutations ****
    /// @dev Collect token fees and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);
        
        /// @dev Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)
        uint256 _avax = address(this).balance;
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        /// @dev Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _savax = IERC20(savax).balanceOf(address(this));
        uint256 _qi = IERC20(qi).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_savax > 0) {
            uint256 _keep = _savax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, savax);
            }
            
            _savax = IERC20(savax).balanceOf(address(this));
        }

        if (_qi > 0) {
            uint256 _keep = _qi.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, qi);
            }
            
            _qi = IERC20(qi).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for sAVAX
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, savax, _wavax.div(2)); 
        }

        /// @dev In the case of sAVAX Rewards, swap half sAVAX for WAVAX
        if(_savax > 0){
            IERC20(savax).safeApprove(joeRouter, 0);
            IERC20(savax).safeApprove(joeRouter, _savax.div(2));   
            _swapTraderJoe(savax, wavax, _savax.div(2)); 
        }

        /// @dev In the case of QI Rewards, swap QI for WAVAX and sAVAX
        if(_qi > 0){
            IERC20(qi).safeApprove(joeRouter, 0);
            IERC20(qi).safeApprove(joeRouter, _qi);   
            _swapTraderJoe(qi, wavax, _qi.div(2));
            _swapTraderJoe(qi, savax, _qi.div(2));
        }

        /// @dev In the case of JOE Rewards, swap JOE for WAVAX and sAVAX
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, savax, _joe.div(2));
        }
        
        /// @dev Add liquidity for AVAX/sAVAX
        _wavax = IERC20(wavax).balanceOf(address(this));
        _savax = IERC20(savax).balanceOf(address(this));
        if (_wavax > 0 && _savax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(savax).safeApprove(joeRouter, 0);
            IERC20(savax).safeApprove(joeRouter, _savax);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                savax,
                _wavax,
                _savax,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _savax = IERC20(savax).balanceOf(address(this));
            _qi = IERC20(qi).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_savax > 0){
                IERC20(savax).safeTransfer(
                    IController(controller).treasury(),
                    _savax
                );
            }
            
            if (_qi > 0){
                IERC20(qi).safeTransfer(
                    IController(controller).treasury(),
                    _qi
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

    /// @notice **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxSavax";
    }
}