pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxYay is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 30;

    // Token addresses
    address public png_avax_yay_lp = 0x04D80d453033450703E3DC2d0C1e0C0281c42D81;
    address public yay = 0x01C2086faCFD7aA38f69A6Bd8C91BEF3BB5adFCa;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_yay_lp,
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
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));

            _swapPangolin(png, wavax, _png);     
        }

        // Swap half WAVAX for YAY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, yay, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/YAY
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _yay = IERC20(yay).balanceOf(address(this));

        if (_wavax > 0 && _yay > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(yay).safeApprove(pangolinRouter, 0);
            IERC20(yay).safeApprove(pangolinRouter, _yay);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                yay,
                _wavax,
                _yay,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _yay = IERC20(yay).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_yay > 0){
                IERC20(yay).safeTransfer(
                    IController(controller).treasury(),
                    _yay
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxYay";
    }
}