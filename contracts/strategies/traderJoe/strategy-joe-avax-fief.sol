// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/FIEF Liquidity Pool with JOE and AVAX rewards
contract StrategyJoeAvaxFief is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public avax_fief_poolId = 52;
    address public joe_avax_fief_lp = 0x939D6eD8a0f7FC90436BA6842D7372250a03fA7c;
    
    address public fief = 0xeA068Fba19CE95f12d252aD8Cb2939225C4Ea02D;
    
    /// @notice Constructor
    /// @param _governance The wallet which will be given ownership of this strategy
    /// @param _strategist The wallet which will be given strategist role for this strategy
    /// @param _controller The contract which will be set as the controller for this strategy 
    /// @param _timelock The contract acting as timelock for this strategy
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_fief_poolId,
            joe_avax_fief_lp,
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
        uint256 _fief = IERC20(fief).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_fief > 0) {
            uint256 _keep = _fief.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, fief);
            }
            
            _fief = IERC20(fief).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for FIEF
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, fief, _wavax.div(2)); 
        }

        // In the case of FIEF Rewards, swap half FIEF for WAVAX
        if(_fief > 0){
            IERC20(fief).safeApprove(joeRouter, 0);
            IERC20(fief).safeApprove(joeRouter, _fief.div(2));   
            _swapTraderJoe(fief, wavax, _fief.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and FIEF
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, fief, _joe.div(2));
        }
        
        // Add liquidity for AVAX/FIEF
        _wavax = IERC20(wavax).balanceOf(address(this));
        _fief = IERC20(fief).balanceOf(address(this));
        if (_wavax > 0 && _fief > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(fief).safeApprove(joeRouter, 0);
            IERC20(fief).safeApprove(joeRouter, _fief);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                fief,
                _wavax,
                _fief,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _fief = IERC20(fief).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_fief > 0){
                IERC20(fief).safeTransfer(
                    IController(controller).treasury(),
                    _fief
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
        return "StrategyJoeAvaxFief";
    }
}