// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxCly is StrategyJoeRushFarmBase {

    uint256 public avax_cly_poolId = 25;

    address public joe_avax_cly_lp = 0x0B2777b0c55AEaAeb56E86B6eEFa6cC2Cfa00e07;
    address public cly = 0xec3492a2508DDf4FDc0cD76F31f340b30d1793e6;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_cly_poolId,
            joe_avax_cly_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeClyToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = cly;
        path[1] = wavax;
        path[2] = snob;
        IERC20(cly).safeApprove(joeRouter, 0);
        IERC20(cly).safeApprove(joeRouter, _keep);
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

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _cly = IERC20(cly).balanceOf(address(this));   //get balance of Cly Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_cly > 0) {
            uint256 _keep2 = _cly.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeClyToSnob(_keep2);
            }
            
            _cly = IERC20(cly).balanceOf(address(this));
          
        }

        // In the case of Cly Rewards, swap cly for wavax
        if(_cly > 0){
            IERC20(cly).safeApprove(joeRouter, 0);
            IERC20(cly).safeApprove(joeRouter, _cly.div(2));   
            _swapTraderJoe(cly, wavax, _cly.div(2));
        }

        // In the case of Avax Rewards, swap wavax for cly
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, cly, _wavax.div(2)); 
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
            _swapTraderJoe(joe, cly, _joe.div(2));
        }

        // Adds in liquidity for AVAX/CLY
        _wavax = IERC20(wavax).balanceOf(address(this));
        _cly = IERC20(cly).balanceOf(address(this));

        if (_wavax > 0 && _cly > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(cly).safeApprove(joeRouter, 0);
            IERC20(cly).safeApprove(joeRouter, _cly);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                cly,
                _wavax,
                _cly,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _cly = IERC20(cly).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_cly > 0){
                IERC20(cly).safeTransfer(
                    IController(controller).treasury(),
                    _cly
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
        return "StrategyJoeAvaxCly";
    }
}