pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxLuna is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 76;

    // Token addresses
    address public png_avax_luna_lp = 0x40e747f27E6398b1f7C017c5ff5c31a2Ab69261c;
    address public luna = 0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_luna_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeLunaToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = luna;
        path[1] = wavax;
        path[2] = snob;
        IERC20(luna).safeApprove(pangolinRouter, 0);
        IERC20(luna).safeApprove(pangolinRouter, _keep);
        _swapPangolinWithPath(path, _keep);
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
        // Collects Token Fees
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _luna = IERC20(luna).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_luna > 0) {
            uint256 _keep = _luna.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeLunaToSnob(_keep);
            }

            _luna = IERC20(luna).balanceOf(address(this));  
        }       

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for LUNA
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, luna, _wavax.div(2)); 
        }      

        // In the case of LUNA Rewards, swap half LUNA for WAVAX and luna
        if(_luna > 0){
            IERC20(luna).safeApprove(pangolinRouter, 0);
            IERC20(luna).safeApprove(pangolinRouter, _luna.div(2));   
            _swapPangolin(luna, wavax, _luna.div(2)); 
        } 

        // In the case of PNG Rewards, swap PNG for WAVAX and LUNA
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, luna); 
        }

        // Adds in liquidity for AVAX/LUNA
        _wavax = IERC20(wavax).balanceOf(address(this));
        _luna = IERC20(luna).balanceOf(address(this));

        if (_wavax > 0 && _luna > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(luna).safeApprove(pangolinRouter, 0);
            IERC20(luna).safeApprove(pangolinRouter, _luna);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                luna,
                _wavax,
                _luna,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _luna = IERC20(luna).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_luna > 0){
                IERC20(luna).safeTransfer(
                    IController(controller).treasury(),
                    _luna
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

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxLuna";
    }
}