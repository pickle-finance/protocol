// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "../bases/strategy-kyber-farm-base.sol";

/// @notice This is the strategy contract for Kyber's USDCE-USDC pair with KNC and AVAX rewards
contract StrategyKyUsdcEUsdc is StrategyKyberFarm {
    address public constant usdce_usdc = 0xD87cD5aa7EfdC4De73EF8c7166D4d1DAA37e2330;
    address public constant usdce_usdc_gauge = 0x845d1D0D9b344fbA8a205461B9E94aEfe258B918;

    address public constant usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; 
    address public constant usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    uint256 public usdce_usdc_poolId = 1; 
    uint256 public index; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyKyberFarm(
        usdce_usdc_gauge,
        usdce_usdc_poolId,
        usdce_usdc, 
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
        IKyber(usdce_usdc_gauge).harvest(usdce_usdc_poolId);

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
        
        // Swapping half the Wavax for USDCE, and the other half for USDC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));      // get the balance of WAVAX tokens
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
               _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));
            _swapTraderJoe(wavax, usdce, _wavax.div(2));
            _swapTraderJoe(wavax, usdc, _wavax.div(2));               
        }

        // Adds liquidity for the USDCE-USDC pair
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        IERC20(usdce).safeApprove(kyberRouter, 0); 
        IERC20(usdce).safeApprove(kyberRouter, _usdce); 

        IERC20(usdc).safeApprove(kyberRouter, 0); 
        IERC20(usdc).safeApprove(kyberRouter, _usdc); 

        ( , ,uint256 vReserve0, uint256 vReserve1, ) = IKyber(usdce_usdc).getTradeInfo();
        uint256 currentRate = (vReserve1 * Q112).div(vReserve0); 

        uint256[] memory ratioBound = new uint256[](2);
        ratioBound[0] = currentRate.mul(99).div(100);
        ratioBound[1] = currentRate.mul(101).div(100);
       
        IKyber(kyberRouter).addLiquidity(
            usdce, 
            usdc, 
            usdce_usdc,
            _usdce,
            _usdc,
            0,
            0,
            [ratioBound[0], ratioBound[1]],
            address(this),
            now + 60
        );

        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _knc= IERC20(knc).balanceOf(address(this));
        _usdce = IERC20(usdce).balanceOf(address(this));  
        _usdc = IERC20(usdc).balanceOf(address(this));       
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

        if (_usdce > 0){
            IERC20(usdce).transfer(
                IController(controller).treasury(),
                _usdce
            );
        }   

        if (_usdc > 0){
            IERC20(usdc).transfer(
                IController(controller).treasury(),
                _usdc
            );
        }  
        _distributePerformanceFeesAndDeposit();  
    }

    // **** Views ****
    function getName() external pure override returns (string memory) {
        return "StrategyKyUsdcEUsdc";
    }
}