pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxAgEUR is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 66;

    // Token addresses
    address public png_avax_ageur_lp = 0x4A045a80967B5ecc440c88dF9a15a3339d43D029;
    address public ageur = 0x6feFd97F328342a8A840546A55FDcfEe7542F9A8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ageur_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeAgEURToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = ageur;
        path[1] = wavax;
        path[2] = snob;
        IERC20(ageur).safeApprove(pangolinRouter, 0);
        IERC20(ageur).safeApprove(pangolinRouter, _keep);
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
        uint256 _ageur = IERC20(ageur).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_ageur > 0) {
            uint256 _keep2 = _ageur.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeAgEURToSnob(_keep2);
            }
            
            _ageur = IERC20(ageur).balanceOf(address(this));
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and AGEUR
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapPangolin(png, ageur, _png.div(2));
        }

        // In the case of AGEUR Rewards, swap AGEUR for WAVAX
        if(_ageur > 0){
            IERC20(ageur).safeApprove(pangolinRouter, 0);
            IERC20(ageur).safeApprove(pangolinRouter, _ageur.div(2));   
            _swapPangolin(ageur, wavax, _ageur.div(2)); 
        }

        // Adds in liquidity for AVAX/AGEUR
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        _ageur = IERC20(ageur).balanceOf(address(this));

        if (_wavax > 0 && _ageur > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ageur).safeApprove(pangolinRouter, 0);
            IERC20(ageur).safeApprove(pangolinRouter, _ageur);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ageur,
                _wavax,
                _ageur,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _ageur = IERC20(ageur).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_ageur > 0){
                IERC20(ageur).safeTransfer(
                    IController(controller).treasury(),
                    _ageur
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
        return "StrategyPngAvaxAgEUR";
    }
}