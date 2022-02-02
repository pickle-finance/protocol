// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxUst is StrategyJoeRushFarmBase {

    uint256 public avax_ust_poolId = 45;

    address public joe_avax_ust_lp = 0x7BF98BD74E19AD8eB5e14076140Ee0103F8F872B;
    address public ust = 0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11;
    address public luna = 0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_ust_poolId,
            joe_avax_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeUstToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = ust;
        path[1] = wavax;
        path[2] = snob;
        IERC20(ust).safeApprove(joeRouter, 0);
        IERC20(ust).safeApprove(joeRouter, _keep);
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

    function _takeFeeLunaToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = luna;
        path[1] = wavax;
        path[2] = snob;
        IERC20(luna).safeApprove(joeRouter, 0);
        IERC20(luna).safeApprove(joeRouter, _keep);
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
   
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); // get balance of WAVAX
        uint256 _ust = IERC20(ust).balanceOf(address(this));     // get balance of UST
        uint256 _luna = IERC20(luna).balanceOf(address(this));   // get balance of LUNA 
        uint256 _joe = IERC20(joe).balanceOf(address(this));     // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_ust > 0) {
            uint256 _keep = _ust.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeUstToSnob(_keep);
            }
            
            _ust = IERC20(ust).balanceOf(address(this));
        }

        if (_luna > 0) {
            uint256 _keep = _luna.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeLunaToSnob(_keep);
            }
            
            _luna = IERC20(luna).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for UST
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ust, _wavax.div(2)); 
        }

        // In the case of UST Rewards, swap half UST for WAVAX
        if(_ust > 0){
            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust.div(2));   
            _swapTraderJoe(ust, wavax, _ust.div(2)); 
        }

        // In the case of LUNA Rewards, swap LUNA for WAVAX and UST
        if(_luna > 0){
            IERC20(luna).safeApprove(joeRouter, 0);
            IERC20(luna).safeApprove(joeRouter, _luna);   
            _swapTraderJoe(luna, wavax, _luna.div(2));
            _swapTraderJoe(luna, ust, _luna.div(2));
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and UST
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, ust, _joe.div(2));
        }
        
        // Adds in liquidity for AVAX/UST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));
        if (_wavax > 0 && _ust > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ust,
                _wavax,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _luna = IERC20(luna).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_ust > 0){
                IERC20(ust).safeTransfer(
                    IController(controller).treasury(),
                    _ust
                );
            }
            
            if (_luna > 0){
                IERC20(luna).safeTransfer(
                    IController(controller).treasury(),
                    _luna
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
        return "StrategyJoeAvaxUst";
    }
}