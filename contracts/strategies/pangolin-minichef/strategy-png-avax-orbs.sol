pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxOrbsLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 36;

    // Token addresses
    address public png_avax_orbs_lp = 0x662135c6745D45392bf011018f95Ad9913DcBf5c;
    address public orbs = 0x340fE1D898ECCAad394e2ba0fC1F93d27c7b717A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_orbs_lp,
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

        // Swap half WAVAX for ORBS
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, orbs, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/ORBS
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _orbs = IERC20(orbs).balanceOf(address(this));

        if (_wavax > 0 && _orbs > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(orbs).safeApprove(pangolinRouter, 0);
            IERC20(orbs).safeApprove(pangolinRouter, _orbs);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                orbs,
                _wavax,
                _orbs,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _orbs = IERC20(orbs).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_orbs > 0){
                IERC20(orbs).safeTransfer(
                    IController(controller).treasury(),
                    _orbs
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAVAXORBSMiniLp";
    }
}