pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxPefiLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 23;

    // Token addresses
    address public png_avax_pefi_lp = 0x494Dd9f783dAF777D3fb4303da4de795953592d0;
    address public pefi = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_pefi_lp,
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

        // Swap half WAVAX for PEFI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, pefi, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/PEFI
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _pefi = IERC20(pefi).balanceOf(address(this));

        if (_wavax > 0 && _pefi > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(pefi).safeApprove(pangolinRouter, 0);
            IERC20(pefi).safeApprove(pangolinRouter, _pefi);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                pefi,
                _wavax,
                _pefi,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _pefi = IERC20(pefi).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_pefi > 0){
                IERC20(pefi).safeTransfer(
                    IController(controller).treasury(),
                    _pefi
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxPefiLp";
    }
}