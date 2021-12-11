pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdtESkillLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 50;

    // Token addresses
    address public png_usdte_skill_lp = 0xF52B3Df311182F43202806ee0E72aCB92d777879;
    address public skill = 0x483416eB3aFA601B9C6385f63CeC0C82B6aBf1fb;
    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_usdte_skill_lp,
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

            _swapPangolin(png, skill, _png.div(2));    
            _swapPangolin(png, usdte, _png.div(2)); 
        }


        // Adds in liquidity for USDTe/SKILL
        uint256 _skill = IERC20(skill).balanceOf(address(this));
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));

        if (_skill > 0 && _usdte > 0) {
            IERC20(skill).safeApprove(pangolinRouter, 0);
            IERC20(skill).safeApprove(pangolinRouter, _skill);

            IERC20(usdte).safeApprove(pangolinRouter, 0);
            IERC20(usdte).safeApprove(pangolinRouter, _usdte);

            IPangolinRouter(pangolinRouter).addLiquidity(
                skill,
                usdte,
                _skill,
                _usdte,
                0,
                0,
                address(this),
                now + 60
            );

            _skill = IERC20(skill).balanceOf(address(this));
            _usdte = IERC20(usdte).balanceOf(address(this));
            
            // Donates DUST
            if (_skill > 0){
                IERC20(skill).transfer(
                    IController(controller).treasury(),
                    _skill
                );
            }
            if (_usdte > 0){
                IERC20(usdte).safeTransfer(
                    IController(controller).treasury(),
                    _usdte
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngUsdtESkillLp";
    }
}