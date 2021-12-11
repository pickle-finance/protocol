pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxHuskyLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 26;

    // Token addresses
    address public png_avax_husky_lp = 0xd05e435Ae8D33faE82E8A9E79b28aaFFb54c1751;
    address public husky = 0x65378b697853568dA9ff8EaB60C13E1Ee9f4a654;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_husky_lp,
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

        // Swap half WAVAX for HUSKY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, husky, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/HUSKY
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _husky = IERC20(husky).balanceOf(address(this));

        if (_wavax > 0 && _husky > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(husky).safeApprove(pangolinRouter, 0);
            IERC20(husky).safeApprove(pangolinRouter, _husky);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                husky,
                _wavax,
                _husky,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _husky = IERC20(husky).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_husky > 0){
                IERC20(husky).safeTransfer(
                    IController(controller).treasury(),
                    _husky
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxHuskyLp";
    }
}