pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxOoeLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 24;

    // Token addresses
    address public png_avax_ooe_lp = 0xE44Ef634A6Eca909eCb0c73cb371140DE85357F9;
    address public ooe = 0x0ebd9537A25f56713E34c45b38F421A1e7191469;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ooe_lp,
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

        // Swap half WAVAX for OOE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, ooe, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/OOE
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _ooe = IERC20(ooe).balanceOf(address(this));

        if (_wavax > 0 && _ooe > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ooe).safeApprove(pangolinRouter, 0);
            IERC20(ooe).safeApprove(pangolinRouter, _ooe);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ooe,
                _wavax,
                _ooe,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _ooe = IERC20(ooe).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_ooe > 0){
                IERC20(ooe).safeTransfer(
                    IController(controller).treasury(),
                    _ooe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxOoeLp";
    }
}