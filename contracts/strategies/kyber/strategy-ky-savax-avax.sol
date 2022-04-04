// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "../bases/strategy-kyber-farm-base.sol";

/// @notice This is the strategy contract for Kyber's sAvax-Avax pair with Qi rewards
contract StrategyKySavaxAvax is StrategyKyberFarm {
    address public constant savax_avax = 0xC6BC80490A3D022ac888b26A5Ae4f1fad89506Bd;
    address public constant savax = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address public constant savax_avax_gauge = 0xa107e6466Be74361840059a11e390200371a7538; 
    uint256 public index; 

    uint256 public savax_avax_poolId = 0; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyKyberFarm(
        savax_avax_gauge,
        savax_avax_poolId,
        savax_avax, 
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
        IKyber(savax_avax_gauge).harvest(savax_avax_poolId);

        // retrieve reward from the vesting contract and increases index for the next reward 
        uint256[] memory indices = new uint256[](1);
        indices[0] = index;
        IRewardLocker(vesting).vestScheduleAtIndices(qi, indices);
        index = index + 1; 

        // Wrapping AVAX into WAVAX      
        uint256 _avax = address(this).balance;                  // get balance of native Avax
        if (_avax > 0) {                                        // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        uint256 _qi = IERC20(qi).balanceOf(address(this));      // get the balance of QI tokens 

        // Swapping all the qi rewards for wavax 
        if (_qi > 0) {
            _swapTraderJoe(qi, wavax, _qi);
        }
        
        // Swapping half the Wavax for SAVAX
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));
            _swapTraderJoe(wavax, savax, _wavax.div(2));
        }

        // Adds liquidity for the sAvax-Wavax pair
        uint256 _savax = IERC20(savax).balanceOf(address(this));
        _wavax = IERC20(wavax).balanceOf(address(this));

        IERC20(savax).safeApprove(kyberRouter, 0); 
        IERC20(savax).safeApprove(kyberRouter, _savax); 

        IERC20(wavax).safeApprove(kyberRouter, 0); 
        IERC20(wavax).safeApprove(kyberRouter, _wavax); 

        ( , ,uint256 vReserve0, uint256 vReserve1, ) = IKyber(savax_avax).getTradeInfo();
        uint256 currentRate = (vReserve1 * Q112).div(vReserve0); 

        uint256[] memory ratioBound = new uint256[](2);
        ratioBound[0] = currentRate.mul(99).div(100);
        ratioBound[1] = currentRate.mul(101).div(100);
       
        IKyber(kyberRouter).addLiquidity(
            savax, 
            wavax, 
            savax_avax,
            _savax,
            _wavax,
            0,
            0,
            [ratioBound[0], ratioBound[1]],
            address(this),
            now + 60
        );


        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _savax = IERC20(savax).balanceOf(address(this));
        _qi = IERC20(qi).balanceOf(address(this));        
        if (_wavax > 0){
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                _wavax
            );
        }      

        if (_savax > 0){
            IERC20(savax).transfer(
                IController(controller).treasury(),
                _savax
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
        return "StrategyKySavaxAvax";
    }
}