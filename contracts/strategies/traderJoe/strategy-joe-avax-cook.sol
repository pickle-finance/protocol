// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxCook is StrategyJoeRushFarmBase {

    uint256 public avax_cook_poolId = 37;

    address public joe_avax_cook_lp = 0x3fcD1d5450e63FA6af495A601E6EA1230f01c4E3;
    address public cook = 0x637afeff75ca669fF92e4570B14D6399A658902f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_cook_poolId,
            joe_avax_cook_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeCookToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = cook;
        path[1] = wavax;
        path[2] = snob;
        IERC20(cook).safeApprove(joeRouter, 0);
        IERC20(cook).safeApprove(joeRouter, _keep);
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
        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _cook = IERC20(cook).balanceOf(address(this));   //get balance of COOK Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

         if (_cook > 0) {
            uint256 _keep2 = _cook.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeCookToSnob(_keep2);
            }
            
            _cook = IERC20(cook).balanceOf(address(this));
        }

        // In the case of COOK Rewards, swap COOK for WAVAX
        if(_cook > 0){
            IERC20(cook).safeApprove(joeRouter, 0);
            IERC20(cook).safeApprove(joeRouter, _cook.div(2));   
            _swapTraderJoe(cook, wavax, _cook.div(2));
        }

        // In the case of AVAX Rewards, swap WAVAX for COOK
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, cook, _wavax.div(2)); 
        }

        
        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, cook, _joe.div(2));
        }

        // Adds in liquidity for AVAX/COOK
        _wavax = IERC20(wavax).balanceOf(address(this));
        _cook = IERC20(cook).balanceOf(address(this));

        if (_wavax > 0 && _cook > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(cook).safeApprove(joeRouter, 0);
            IERC20(cook).safeApprove(joeRouter, _cook);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                cook,
                _wavax,
                _cook,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _cook = IERC20(cook).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_cook > 0){
                IERC20(cook).safeTransfer(
                    IController(controller).treasury(),
                    _cook
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

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxCook";
    }
}