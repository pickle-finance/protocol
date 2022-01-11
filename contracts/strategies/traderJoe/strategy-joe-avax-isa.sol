// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxIsa is StrategyJoeRushFarmBase {

    uint256 public avax_isa_poolId = 36;

    address public joe_avax_isa_lp = 0x9155f441FFDfA81b13E385bfAc6b3825C05184Ee;
    address public isa = 0x3EeFb18003D033661f84e48360eBeCD181A84709;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_isa_poolId,
            joe_avax_isa_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeIsaToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = isa;
        path[1] = wavax;
        path[2] = snob;
        IERC20(isa).safeApprove(joeRouter, 0);
        IERC20(isa).safeApprove(joeRouter, _keep);
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
        // Collects JOE tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _isa = IERC20(isa).balanceOf(address(this));     //get balance of ISA Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

         if (_isa > 0) {
            uint256 _keep2 = _isa.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeIsaToSnob(_keep2);
            }

            _isa = IERC20(isa).balanceOf(address(this));
        }

        //In the case of ISA Rewards, swap ISA for WAVAX
        if(_isa > 0){
            IERC20(isa).safeApprove(joeRouter, 0);
            IERC20(isa).safeApprove(joeRouter, _isa.div(2));   
            _swapTraderJoe(isa, wavax, _isa.div(2));
        }

        //in the case of AVAX Rewards, swap WAVAX for ISA
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, isa, _wavax.div(2)); 
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
            _swapTraderJoe(joe, isa, _joe.div(2));
        }

        // Adds in liquidity for AVAX/ISA
        _wavax = IERC20(wavax).balanceOf(address(this));
        _isa = IERC20(isa).balanceOf(address(this));

        if (_wavax > 0 && _isa > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(isa).safeApprove(joeRouter, 0);
            IERC20(isa).safeApprove(joeRouter, _isa);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                isa,
                _wavax,
                _isa,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _isa = IERC20(isa).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_isa > 0){
                IERC20(isa).safeTransfer(
                    IController(controller).treasury(),
                    _isa
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
        return "StrategyJoeAvaxIsa";
    }
}