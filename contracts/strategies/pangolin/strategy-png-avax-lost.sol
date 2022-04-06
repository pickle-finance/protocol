pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/LOST Liquidity Pool with PNG and LOST rewards
contract StrategyPngAvaxLost is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 105;
    address public png_avax_lost_lp = 0x8461681211B49c15e20B3Cfd4c63BE258878B7D9;
    
    address public lost = 0x449674B82F05d498E126Dd6615a1057A9c088f2C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_lost_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****
    // Collect token fees and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)  
        uint256 _avax = address(this).balance;              
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }

        // Check token balances, take fee for each token, then update balances
        uint256 _lost = IERC20(lost).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));

        if (_lost > 0) {
            _swapPangolin(lost, wavax, _lost); 
        }

        if (_png > 0) {
            _swapPangolin(png, wavax, _png);
        }

        // In the case of AVAX Rewards take fee and swap half WAVAX for LOST
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if(_wavax > 0){
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }
            _wavax = IERC20(wavax).balanceOf(address(this));
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, lost, _wavax.div(2)); 
        }      

        // Add in liquidity for AVAX/LOST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _lost = IERC20(lost).balanceOf(address(this));

        if (_wavax > 0 && _lost > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(lost).safeApprove(pangolinRouter, 0);
            IERC20(lost).safeApprove(pangolinRouter, _lost);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                lost,
                _wavax,
                _lost,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _lost = IERC20(lost).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_lost > 0){
                IERC20(lost).safeTransfer(
                    IController(controller).treasury(),
                    _lost
                );
            }

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }
        }
    
        _distributePerformanceFeesAndDeposit();
    }

    /// **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxLost";
    }
}