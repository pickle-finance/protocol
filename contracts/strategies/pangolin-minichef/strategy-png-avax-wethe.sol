pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxWethE is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 8;

    // Token addresses
    address public png_avax_wethe_lp = 0x7c05d54fc5CB6e4Ad87c6f5db3b807C94bB89c52;
    address public wethe = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_wethe_lp,
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

        // Swap half WAVAX for WETHe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, wethe, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/WETHe
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _wethe = IERC20(wethe).balanceOf(address(this));

        if (_wavax > 0 && _wethe > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(wethe).safeApprove(pangolinRouter, 0);
            IERC20(wethe).safeApprove(pangolinRouter, _wethe);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                wethe,
                _wavax,
                _wethe,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _wethe = IERC20(wethe).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_wethe > 0){
                IERC20(wethe).safeTransfer(
                    IController(controller).treasury(),
                    _wethe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxWethE";
    }
}