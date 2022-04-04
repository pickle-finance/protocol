// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "../bases/strategy-kyber-farm-base.sol";

/// @notice This is the strategy contract for Kyber's KNC-QI pair with KNC rewards
contract StrategyKyKncQi is StrategyKyberFarm {
    address public constant knc_qi = 0x896e359edD6aE688a4eB259af4e208128D4c4e20;
    address public constant knc_qi_gauge = 0x89929Bc485cE72D2Af7b7283B40b921e9F4f80b3;

    uint256 public knc_qi_poolId = 1; 
    uint256 public index; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyKyberFarm(
        knc_qi_gauge,
        knc_qi_poolId,
        knc_qi, 
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
        IKyber(knc_qi_gauge).harvest(knc_qi_poolId);

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
        
        // Swapping half the Wavax for KNC, and the other half for QI 
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
               _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));
            _swapToken(wavax, knc, _wavax.div(2));
            _swapTraderJoe(wavax, qi, _wavax.div(2));               
        }

        // Adds liquidity for the sAvax-Wavax pair
        _knc = IERC20(knc).balanceOf(address(this));
        uint256 _qi = IERC20(qi).balanceOf(address(this));

        IERC20(knc).safeApprove(kyberRouter, 0); 
        IERC20(knc).safeApprove(kyberRouter, _knc); 

        IERC20(qi).safeApprove(kyberRouter, 0); 
        IERC20(qi).safeApprove(kyberRouter, _qi); 

        ( , ,uint256 vReserve0, uint256 vReserve1, ) = IKyber(knc_qi).getTradeInfo();
        uint256 currentRate = (vReserve1 * Q112).div(vReserve0); 

        uint256[] memory ratioBound = new uint256[](2);
        ratioBound[0] = currentRate.mul(99).div(100);
        ratioBound[1] = currentRate.mul(101).div(100);
       
        IKyber(kyberRouter).addLiquidity(
            knc, 
            qi, 
            knc_qi,
            _knc,
            _qi,
            0,
            0,
            [ratioBound[0], ratioBound[1]],
            address(this),
            now + 60
        );

        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _knc= IERC20(knc).balanceOf(address(this));
        _qi = IERC20(qi).balanceOf(address(this));        
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

        if (_qi > 0){
            IERC20(qi).transfer(
                IController(controller).treasury(),
                _qi
            );
        }   
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****
    function getName() external pure override returns (string memory) {
        return "StrategyKyKncQi";
    }
}