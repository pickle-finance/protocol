pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxCraft is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 41;

    // Token addresses
    address public png_avax_craft_lp = 0xe9E5A27314f1b87ea6484139B98Eaf816c6688a4;
    address public craft = 0x8aE8be25C23833e0A01Aa200403e826F611f9CD2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_craft_lp,
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

        // Swap half WAVAX for CRAFT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, craft, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/CRAFT
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _craft = IERC20(craft).balanceOf(address(this));

        if (_wavax > 0 && _craft > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(craft).safeApprove(pangolinRouter, 0);
            IERC20(craft).safeApprove(pangolinRouter, _craft);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                craft,
                _wavax,
                _craft,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _craft = IERC20(craft).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_craft > 0){
                IERC20(craft).safeTransfer(
                    IController(controller).treasury(),
                    _craft
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxCraft";
    }
}