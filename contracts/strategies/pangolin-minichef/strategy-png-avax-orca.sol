pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxOrcaLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 45;

    // Token addresses
    address public png_avax_orca_lp = 0x73e6CB72a79dEa7ed75EF5eD6f8cFf86C9128eF5;
    address public orca = 0x8B1d98A91F853218ddbb066F20b8c63E782e2430;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_orca_lp,
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

        // Swap half WAVAX for ORCA
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, orca, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/ORCA
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _orca = IERC20(orca).balanceOf(address(this));

        if (_wavax > 0 && _orca > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(orca).safeApprove(pangolinRouter, 0);
            IERC20(orca).safeApprove(pangolinRouter, _orca);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                orca,
                _wavax,
                _orca,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _orca = IERC20(orca).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_orca > 0){
                IERC20(orca).safeTransfer(
                    IController(controller).treasury(),
                    _orca
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxOrcaLp";
    }
}