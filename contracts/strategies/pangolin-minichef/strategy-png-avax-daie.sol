pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxDaiELp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 6;

    // Token addresses
    address public png_avax_daie_lp = 0xbA09679Ab223C6bdaf44D45Ba2d7279959289AB0;
    address public daie = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_daie_lp,
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

        // Swap half WAVAX for DAIe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, daie, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/DAIe
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _daie = IERC20(daie).balanceOf(address(this));

        if (_wavax > 0 && _daie > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(daie).safeApprove(pangolinRouter, 0);
            IERC20(daie).safeApprove(pangolinRouter, _daie);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                daie,
                _wavax,
                _daie,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _daie = IERC20(daie).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_daie > 0){
                IERC20(daie).safeTransfer(
                    IController(controller).treasury(),
                    _daie
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxDaiELp";
    }
}