// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/CRAFT Liquidity Pool with JOE and CRAFT rewards
contract StrategyJoeAvaxCraft is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 20;
    address public joe_avax_craft_lp = 0x86D1b1Ab4812a104BC1Ea1FbD07809DE636E6C6b;
    
    address public craft = 0x8aE8be25C23833e0A01Aa200403e826F611f9CD2;
    
    /// @notice Constructor
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            lp_poolId,
            joe_avax_craft_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice Collect token fees, swap rewards, and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);
        
        // Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)
        uint256 _avax = address(this).balance;
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _craft = IERC20(craft).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_craft > 0) {
            uint256 _keep = _craft.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, craft);
            }
            
            _craft = IERC20(craft).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for CRAFT
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, craft, _wavax.div(2)); 
        }

        // In the case of CRAFT Rewards, swap half CRAFT for WAVAX
        if(_craft > 0){
            IERC20(craft).safeApprove(joeRouter, 0);
            IERC20(craft).safeApprove(joeRouter, _craft.div(2));   
            _swapTraderJoe(craft, wavax, _craft.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and CRAFT
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, craft, _joe.div(2));
        }
        
        // Add liquidity for AVAX/CRAFT
        _wavax = IERC20(wavax).balanceOf(address(this));
        _craft = IERC20(craft).balanceOf(address(this));
        if (_wavax > 0 && _craft > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(craft).safeApprove(joeRouter, 0);
            IERC20(craft).safeApprove(joeRouter, _craft);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                craft,
                _wavax,
                _craft,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _craft = IERC20(craft).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_craft > 0){
                IERC20(craft).safeTransfer(
                    IController(controller).treasury(),
                    _craft
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

    /// @notice Return the name of the strategy
    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxCraft";
    }
}