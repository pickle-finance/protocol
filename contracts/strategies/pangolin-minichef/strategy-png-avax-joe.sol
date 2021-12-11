pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxJoeLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 14;

    // Token addresses
    address public png_avax_joe_lp = 0x134Ad631337E8Bf7E01bA641fB650070a2e0efa8;
    address public joe = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_joe_lp,
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

        // Swap half WAVAX for JOE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, joe, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/JOE
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _joe = IERC20(joe).balanceOf(address(this));

        if (_wavax > 0 && _joe > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(joe).safeApprove(pangolinRouter, 0);
            IERC20(joe).safeApprove(pangolinRouter, _joe);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                joe,
                _wavax,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_joe > 0){
                IERC20(joe).safeTransfer(
                    IController(controller).treasury(),
                    _joe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxJoeLp";
    }
}