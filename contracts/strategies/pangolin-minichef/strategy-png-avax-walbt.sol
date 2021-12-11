pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxWalbtLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 13;

    // Token addresses
    address public png_avax_walbt_lp = 0x4555328746f1b6a9b03dE964C90eCd99d75bFFbc;
    address public walbt = 0x9E037dE681CaFA6E661e6108eD9c2bd1AA567Ecd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_walbt_lp,
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

        // Swap half WAVAX for WALBT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, walbt, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/WALBT
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _walbt = IERC20(walbt).balanceOf(address(this));

        if (_wavax > 0 && _walbt > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(walbt).safeApprove(pangolinRouter, 0);
            IERC20(walbt).safeApprove(pangolinRouter, _walbt);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                walbt,
                _wavax,
                _walbt,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _walbt = IERC20(walbt).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_walbt > 0){
                IERC20(walbt).safeTransfer(
                    IController(controller).treasury(),
                    _walbt
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxWalbtLp";
    }
}