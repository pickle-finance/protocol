pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxVeeLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 31;

    // Token addresses
    address public png_avax_vee_lp = 0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10;
    address public vee = 0x3709E8615E02C15B096f8a9B460ccb8cA8194e86;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_vee_lp,
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

            _swapPangolin(png, wavax, _png.div(2));    
        }

        // Swap half WAVAX for VEE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, vee, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/VEE
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _vee = IERC20(vee).balanceOf(address(this));

        if (_wavax > 0 && _vee > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(vee).safeApprove(pangolinRouter, 0);
            IERC20(vee).safeApprove(pangolinRouter, _vee);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                vee,
                _wavax,
                _vee,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _vee = IERC20(vee).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_vee > 0){
                IERC20(vee).safeTransfer(
                    IController(controller).treasury(),
                    _vee
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxVeeLp";
    }
}