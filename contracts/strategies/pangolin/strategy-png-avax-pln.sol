pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxPln is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 70;

    // Token addresses
    address public png_avax_pln_lp = 0x911aE99620f4c42038FC4D1B6Da6F5135Bee8356;
    address public pln = 0x7b2B702706D9b361dfE3f00bD138C0CFDA7FB2Cf;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_pln_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeePlnToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = pln;
        path[1] = wavax;
        path[2] = snob;
        IERC20(pln).safeApprove(pangolinRouter, 0);
        IERC20(pln).safeApprove(pangolinRouter, _keep);
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
        uint256 _pln = IERC20(pln).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_pln > 0) {
            uint256 _keep2 = _pln.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeePlnToSnob(_keep2);
            }
            
            _pln = IERC20(pln).balanceOf(address(this));
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and PLN
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapPangolin(png, pln, _png.div(2));
        }

        // In the case of PLN Rewards, swap PLN for WAVAX
        if(_pln > 0){
            IERC20(pln).safeApprove(pangolinRouter, 0);
            IERC20(pln).safeApprove(pangolinRouter, _pln.div(2));   
            _swapPangolin(pln, wavax, _pln.div(2)); 
        }

        // Adds in liquidity for AVAX/PLN
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        _pln = IERC20(pln).balanceOf(address(this));

        if (_wavax > 0 && _pln > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(pln).safeApprove(pangolinRouter, 0);
            IERC20(pln).safeApprove(pangolinRouter, _pln);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                pln,
                _wavax,
                _pln,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _pln = IERC20(pln).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_pln > 0){
                IERC20(pln).safeTransfer(
                    IController(controller).treasury(),
                    _pln
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
        return "StrategyPngAvaxPln";
    }
}