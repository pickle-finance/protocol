pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxMoney is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 81;

    // Token addresses
    address public png_avax_money_lp = 0x3e58e8D1c403c353f6cFe8b9582bB17bD7f433f3;
    address public money = 0x0f577433Bf59560Ef2a79c124E9Ff99fCa258948;
    address public more = 0xd9D90f882CDdD6063959A9d837B05Cb748718A05;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_money_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        uint256 _more = IERC20(more).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_more > 0) {
            uint256 _keep = _more.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, more);
            }

            _more = IERC20(more).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for MONEY
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, money, _wavax.div(2)); 
        }      
    
        // In the case of PNG Rewards, swap PNG for WAVAX and MONEY
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, money); 
        }

        // In the case of MORE Rewards, swap MORE for WAVAX and MONEY
        if(_more > 0){
            IERC20(more).safeApprove(pangolinRouter, 0);
            IERC20(more).safeApprove(pangolinRouter, _more);   
            _swapPangolin(more, wavax, _more.div(2));
            _swapBaseToToken(_more.div(2), more, money); 
        }

        // Adds in liquidity for AVAX/MONEY
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _money = IERC20(money).balanceOf(address(this));

        if (_wavax > 0 && _money > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(money).safeApprove(pangolinRouter, 0);
            IERC20(money).safeApprove(pangolinRouter, _money);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                money,
                _wavax,
                _money,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _money = IERC20(money).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            _more = IERC20(more).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_money > 0){
                IERC20(money).safeTransfer(
                    IController(controller).treasury(),
                    _money
                );
            }

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }

            if (_more > 0){
                IERC20(more).safeTransfer(
                    IController(controller).treasury(),
                    _more
                );
            }
        }
    
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxMoney";
    }
}