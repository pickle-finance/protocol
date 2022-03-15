pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/FEED Liquidity Pool with PNG and FEED rewards
contract StrategyPngAvaxFeed is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 67;
    address public png_avax_feed_lp = 0xe8579e213E85d52f6559CB0070eA6c912718b4f4;
    
    address public feed = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_feed_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice **** State Mutations ****
    /// @dev Collect token fees and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        /// @dev Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)  
        uint256 _avax = address(this).balance;              
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }

        /// @dev Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _feed = IERC20(feed).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_feed > 0) {
            uint256 _keep = _feed.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, feed);
            }  

            _feed = IERC20(feed).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for FEED
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, feed, _wavax.div(2)); 
        }      

        /// @dev In the case of FEED Rewards, swap half FEED for WAVAX
         if(_feed > 0){
            IERC20(feed).safeApprove(pangolinRouter, 0);
            IERC20(feed).safeApprove(pangolinRouter, _feed.div(2));   
            _swapPangolin(feed, wavax, _feed.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and FEED
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > FEED
            _swapBaseToToken(_png.div(2), png, feed);    
        }

        /// @dev Add in liquidity for AVAX/FEED
        _wavax = IERC20(wavax).balanceOf(address(this));
        _feed = IERC20(feed).balanceOf(address(this));

        if (_wavax > 0 && _feed > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(feed).safeApprove(pangolinRouter, 0);
            IERC20(feed).safeApprove(pangolinRouter, _feed);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                feed,
                _wavax,
                _feed,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _feed = IERC20(feed).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_feed > 0){
                IERC20(feed).safeTransfer(
                    IController(controller).treasury(),
                    _feed
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

    /// @notice **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxFeed";
    }
}