// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/MONEy Liquidity Pool with JOE and MORE rewards
contract StrategyJoeAvaxMoney is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 57;
    address public joe_avax_money_lp = 0x66D12e1cb13EAbAB21f1Fb6628B1Ef33C6dED5a7;
    
    address public money = 0x0f577433Bf59560Ef2a79c124E9Ff99fCa258948;
    address public more = 0xd9D90f882CDdD6063959A9d837B05Cb748718A05;
    
    /// @notice Constructor
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            lp_poolId,
            joe_avax_money_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice Collect token fees, swap rewards, and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);
        
        // Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)
        uint256 _avax = address(this).balance;
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _money = IERC20(money).balanceOf(address(this)); 
        uint256 _more = IERC20(more).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_money > 0) {
            uint256 _keep = _money.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, money);
            }
            
            _money = IERC20(money).balanceOf(address(this));
        }

        if (_more > 0) {
            uint256 _keep = _money.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, more);
            }
            
            _more = IERC20(more).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for MONEy
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, money, _wavax.div(2)); 
        }

        // In the case of MONEy Rewards, swap half MONEy for WAVAX
        if(_money > 0){
            IERC20(money).safeApprove(joeRouter, 0);
            IERC20(money).safeApprove(joeRouter, _money.div(2));   
            _swapTraderJoe(money, wavax, _money.div(2)); 
        }

        // In the case of MORE Rewards, swap MORE for WAVAX and MONEy
        if(_more > 0){
            IERC20(more).safeApprove(joeRouter, 0);
            IERC20(more).safeApprove(joeRouter, _more);
            _swapTraderJoe(more, wavax, _more.div(2));
            _swapTraderJoe(more, money, _more.div(2));
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and MONEy
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, money, _joe.div(2));
        }
        
        // Add liquidity for AVAX/MONEy
        _wavax = IERC20(wavax).balanceOf(address(this));
        _money = IERC20(money).balanceOf(address(this));
        if (_wavax > 0 && _money > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(money).safeApprove(joeRouter, 0);
            IERC20(money).safeApprove(joeRouter, _money);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                money,
                _wavax,
                _money,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _money = IERC20(money).balanceOf(address(this));
            _more = IERC20(more).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
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

            if (_more > 0){
                IERC20(more).safeTransfer(
                    IController(controller).treasury(),
                    _more
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

    /// @notice Return the name of the strategy
    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMoney";
    }
}