// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxMore is StrategyJoeRushFarmBase {

    uint256 public avax_more_poolId = 44;

    address public joe_avax_more_lp = 0xb8361D0E3F3B0fc5e6071f3a3C3271223C49e3d9;
    address public more = 0xd9D90f882CDdD6063959A9d837B05Cb748718A05;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_more_poolId,
            joe_avax_more_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeMoreToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = more;
        path[1] = wavax;
        path[2] = snob;
        IERC20(more).safeApprove(joeRouter, 0);
        IERC20(more).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  // get balance of WAVAX
        uint256 _more = IERC20(more).balanceOf(address(this));    // get balance of MORE 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_more > 0) {
            uint256 _keep = _more.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeMoreToSnob(_keep);
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

        // In the case of WAVAX Rewards, swap half WAVAX for MORE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, more, _wavax.div(2));
        }

        // In the case of MORE Rewards, swap half MORE for WAVAX
        if(_more > 0){
            IERC20(more).safeApprove(joeRouter, 0);
            IERC20(more).safeApprove(joeRouter, _more.div(2));   
            _swapTraderJoe(more, wavax, _more.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and MORE        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, more, _joe.div(2));
        }

        // Adds in liquidity for AVAX/MORE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _more = IERC20(more).balanceOf(address(this));

        if (_wavax > 0 && _more > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(more).safeApprove(joeRouter, 0);
            IERC20(more).safeApprove(joeRouter, _more);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                more,
                _wavax,
                _more,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _more = IERC20(more).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_more > 0){
                IERC20(more).safeTransfer(
                    IController(controller).treasury(),
                    _more
                );
            } 

            if (_joe > 0){
                IERC20(joe).transfer(
                    IController(controller).treasury(),
                    _joe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMore";
    }
}