pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxRocoLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 17;

    // Token addresses
    address public png_avax_roco_lp = 0x4a2cB99e8d91f82Cf10Fb97D43745A1f23e47caA;
    address public roco = 0xb2a85C5ECea99187A977aC34303b80AcbDdFa208;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_roco_lp,
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

        // Swap half WAVAX for token
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, roco, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/Axial
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _roco = IERC20(roco).balanceOf(address(this));

        if (_wavax > 0 && _roco > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(roco).safeApprove(pangolinRouter, 0);
            IERC20(roco).safeApprove(pangolinRouter, _roco);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                roco,
                _wavax,
                _roco,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _roco = IERC20(roco).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_roco > 0){
                IERC20(roco).safeTransfer(
                    IController(controller).treasury(),
                    _roco
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxRocoLp";
    }
}