// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxKloLp is StrategyJoeRushFarmBase {

    uint256 public avax_klo_poolId = 24;

    address public joe_avax_klo_lp = 0xb2fF0817ad078C92C3AfB82326592e06C92581B8;
    address public klo = 0xb27c8941a7Df8958A1778c0259f76D1F8B711C35;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_klo_poolId,
            joe_avax_klo_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeKloToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = klo;
        path[1] = wavax;
        path[2] = snob;
        IERC20(klo).safeApprove(joeRouter, 0);
        IERC20(klo).safeApprove(joeRouter, _keep);
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
        
        uint256 _klo = IERC20(klo).balanceOf(address(this));      //get balance of KLO Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  //get balance of WAVAX

        // In the case of AVAX Rewards, swap WAVAX for KLO
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, klo, _wavax.div(2)); 

        }

        // In the case of KLO Rewards, swap KLO for WAVAX
        if (_klo > 0) {
            uint256 _keep2 = _klo.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeKloToSnob(_keep2);
            }
            
            _klo = IERC20(klo).balanceOf(address(this));

            IERC20(klo).safeApprove(joeRouter, 0);
            IERC20(klo).safeApprove(joeRouter, _klo.div(2));   
            _swapTraderJoe(klo, wavax, _klo.div(2));
          
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
            _swapTraderJoe(joe, klo, _joe.div(2));
        }

        // Adds in liquidity for AVAX/KLO
        _wavax = IERC20(wavax).balanceOf(address(this));
        _klo = IERC20(klo).balanceOf(address(this));

        if (_wavax > 0 && _klo > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(klo).safeApprove(joeRouter, 0);
            IERC20(klo).safeApprove(joeRouter, _klo);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                klo,
                _wavax,
                _klo,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _klo = IERC20(klo).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_klo > 0){
                IERC20(klo).safeTransfer(
                    IController(controller).treasury(),
                    _klo
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxKloLp";
    }
}