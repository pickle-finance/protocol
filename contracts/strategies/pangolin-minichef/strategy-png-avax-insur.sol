pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxInsur is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 35;

    // Token addresses
    address public png_avax_insur_lp = 0xEd764838FA66993892fa37D57d4036032B534f24;
    address public insur = 0x544c42fBB96B39B21DF61cf322b5EDC285EE7429;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_insur_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
    
    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));

            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            _swapPangolin(png, wavax, _png); 
        }

        // Swap half WAVAX for INSUR
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, insur, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/INSUR
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _insur = IERC20(insur).balanceOf(address(this));

        if (_wavax > 0 && _insur > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(insur).safeApprove(pangolinRouter, 0);
            IERC20(insur).safeApprove(pangolinRouter, _insur);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                insur,
                _wavax,
                _insur,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _insur = IERC20(insur).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_insur > 0){
                IERC20(insur).safeTransfer(
                    IController(controller).treasury(),
                    _insur
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxInsur";
    }
}