pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxQiLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 19;

    // Token addresses
    address public png_avax_qi_lp = 0xE530dC2095Ef5653205CF5ea79F8979a7028065c;
    address public qi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_qi_lp,
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

        // Swap half WAVAX for QI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, qi, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/QI
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _qi = IERC20(qi).balanceOf(address(this));

        if (_wavax > 0 && _qi > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(qi).safeApprove(pangolinRouter, 0);
            IERC20(qi).safeApprove(pangolinRouter, _qi);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                qi,
                _wavax,
                _qi,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _qi = IERC20(qi).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_qi > 0){
                IERC20(qi).safeTransfer(
                    IController(controller).treasury(),
                    _qi
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxQiLp";
    }
}