// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "../bases/strategy-kyber-farm-base.sol";

/// @notice This is the strategy contract for Kyber's USDTE-USDT pair with KNC and AVAX rewards
contract StrategyKyUsdtEUsdt is StrategyKyberFarm {
    address public constant usdte_usdt = 0x88D23fc2DF1E5d07e58105301A560cf92A4E6ecb;
    address public constant usdte_usdt_gauge = 0x845d1D0D9b344fbA8a205461B9E94aEfe258B918;

    address public constant usdt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; 
    address public constant usdte= 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    uint256 public usdte_usdt_poolId = 0; 
    uint256 public index; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyKyberFarm(
        usdte_usdt_gauge,
        usdte_usdt_poolId,
        usdte_usdt, 
        _governance, 
        _strategist, 
        _controller, 
        _timelock
    )
    {
        index = 0;
    } 
    
    // ***** Collects Rewards and Restakes ****** // 
    function harvest() public override onlyBenevolent {

        // Harvests the rewards from the specific pool on kyber finance 
        IKyber(usdte_usdt_gauge).harvest(usdte_usdt_poolId);

        // Retrieve reward from the vesting contract and increases index for the next reward 
        uint256[] memory indices = new uint256[](1);
        indices[0] = index;
        IRewardLocker(vesting).vestScheduleAtIndices(knc, indices);
        index = index + 1; 

        // Wrapping AVAX into WAVAX       
        uint256 _avax = address(this).balance;                        // get balance of native Avax
        if (_avax > 0) {                                              // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // Swapping all the knc rewards for wavax 
        uint256 _knc = IERC20(knc).balanceOf(address(this));          // get the balance of KNC tokens
        if (_knc > 0) {
            _swapToken(knc, wavax, _knc);
        }
        
        // Swapping half the Wavax for USDTE, and the other half for USDT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));      // get the balance of WAVAX tokens
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
               _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));
            _swapTraderJoe(wavax, usdte, _wavax.div(2));
            _swapTraderJoe(wavax, usdt, _wavax.div(2));               
        }

        // Adds liquidity for the USDTE-USDT pair
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));

        IERC20(usdt).safeApprove(kyberRouter, 0); 
        IERC20(usdt).safeApprove(kyberRouter, _usdt); 

        IERC20(usdte).safeApprove(kyberRouter, 0); 
        IERC20(usdte).safeApprove(kyberRouter, _usdte); 

        ( , ,uint256 vReserve0, uint256 vReserve1, ) = IKyber(usdte_usdt).getTradeInfo();
        uint256 currentRate = (vReserve1 * Q112).div(vReserve0); 

        uint256[] memory ratioBound = new uint256[](2);
        ratioBound[0] = currentRate.mul(99).div(100);
        ratioBound[1] = currentRate.mul(101).div(100);
       
        IKyber(kyberRouter).addLiquidity(
            usdt, 
            usdte, 
            usdte_usdt,
            _usdt,
            _usdte,
            0,
            0,
            [ratioBound[0], ratioBound[1]],
            address(this),
            now + 60
        );

        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _knc= IERC20(knc).balanceOf(address(this));
        _usdte = IERC20(usdte).balanceOf(address(this));  
        _usdt = IERC20(usdt).balanceOf(address(this));       
        if (_wavax > 0){
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                _wavax
            );
        }      

        if (_knc > 0){
            IERC20(knc).transfer(
                IController(controller).treasury(),
                _knc
            );
        }     

        if (_usdte > 0){
            IERC20(usdte).transfer(
                IController(controller).treasury(),
                _usdte
            );
        }   

        if (_usdt > 0){
            IERC20(usdt).transfer(
                IController(controller).treasury(),
                _usdt
            );
        }   
        _distributePerformanceFeesAndDeposit();     
    }

    // **** Views ****
    function getName() external pure override returns (string memory) {
        return "StrategyKyUsdtEUsdt";
    }
}