pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxLoot is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 65;

    // Token addresses
    address public png_avax_loot_lp = 0x1bFae75b28925BF4a5bf830c141EA29CB0A868F1;
    address public loot = 0x7f041ce89A2079873693207653b24C15B5e6A293;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_loot_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeLootToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = loot;
        path[1] = wavax;
        path[2] = snob;
        IERC20(loot).safeApprove(pangolinRouter, 0);
        IERC20(loot).safeApprove(pangolinRouter, _keep);
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
        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _png = IERC20(png).balanceOf(address(this));
        uint256 _loot = IERC20(loot).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_loot > 0) {
            uint256 _keep2 = _loot.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeLootToSnob(_keep2);
            }
            
            _loot = IERC20(loot).balanceOf(address(this));
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and LOOT
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapPangolin(png, loot, _png.div(2));
        }

        // In the case of LOOT Rewards, swap LOOT for WAVAX
        if(_loot > 0){
            IERC20(loot).safeApprove(pangolinRouter, 0);
            IERC20(loot).safeApprove(pangolinRouter, _loot.div(2));   
            _swapPangolin(loot, wavax, _loot.div(2)); 
        }

        

        // Adds in liquidity for AVAX/LOOT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        _loot = IERC20(loot).balanceOf(address(this));

        if (_wavax > 0 && _loot > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(loot).safeApprove(pangolinRouter, 0);
            IERC20(loot).safeApprove(pangolinRouter, _loot);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                loot,
                _wavax,
                _loot,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _loot = IERC20(loot).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_loot > 0){
                IERC20(loot).safeTransfer(
                    IController(controller).treasury(),
                    _loot
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
        return "StrategyPngAvaxLoot";
    }
}