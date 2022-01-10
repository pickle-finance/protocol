// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeFraxgOhm is StrategyJoeRushFarmBase {

    uint256 public frax_gohm_poolId = 34;

    address public joe_frax_gohm_lp = 0x3E6Be71dE004363379d864006AAC37C9F55F8329;
    address public gohm = 0x321E7092a180BB43555132ec53AaA65a5bF84251;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            frax_gohm_poolId,
            joe_frax_gohm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeegOhmToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = gohm;
        path[1] = wavax;
        path[2] = snob;
        IERC20(gohm).safeApprove(joeRouter, 0);
        IERC20(gohm).safeApprove(joeRouter, _keep);
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

    function _takeFeeFraxToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = frax;
        path[1] = wavax;
        path[2] = snob;
        IERC20(frax).safeApprove(joeRouter, 0);
        IERC20(frax).safeApprove(joeRouter, _keep);
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
        
        uint256 _gohm = IERC20(gohm).balanceOf(address(this));      //get balance of gOHM Tokens
        uint256 _frax = IERC20(frax).balanceOf(address(this));      //get balance of FRAX

        // In the case of gOHM Rewards, swap gOHM for FRAX
        if (_gohm > 0) {
            uint256 _keep1 = _gohm.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeegOhmToSnob(_keep1);
            }
            
            _gohm = IERC20(gohm).balanceOf(address(this));

            IERC20(gohm).safeApprove(joeRouter, 0);
            IERC20(gohm).safeApprove(joeRouter, _gohm.div(2));   
            _swapTraderJoe(gohm, frax, _gohm.div(2)); 

        }

        // In the case of FRAX Rewards, swap FRAX for gOHM 
        if (_frax > 0) {
            uint256 _keep2 = _frax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeFraxToSnob(_keep2);
            }
            
            _frax = IERC20(frax).balanceOf(address(this));

            IERC20(frax).safeApprove(joeRouter, 0);
            IERC20(frax).safeApprove(joeRouter, _frax.div(2));   
            _swapTraderJoe(frax, gohm, _frax.div(2));
          
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

            _swapTraderJoe(joe, gohm, _joe.div(2));
            _swapTraderJoe(joe, frax, _joe.div(2));
        }

        // Adds in liquidity for FRAX/gOHM
        _frax = IERC20(frax).balanceOf(address(this));
        _gohm = IERC20(gohm).balanceOf(address(this));

        if (_frax > 0 && _gohm > 0) {
            IERC20(frax).safeApprove(joeRouter, 0);
            IERC20(frax).safeApprove(joeRouter, _frax);

            IERC20(gohm).safeApprove(joeRouter, 0);
            IERC20(gohm).safeApprove(joeRouter, _gohm);

            IJoeRouter(joeRouter).addLiquidity(
                frax,
                gohm,
                _frax,
                _gohm,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _frax = IERC20(frax).balanceOf(address(this));
            _gohm = IERC20(gohm).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_frax > 0){
                IERC20(frax).transfer(
                    IController(controller).treasury(),
                    _frax
                );
            }
            
            if (_gohm > 0){
                IERC20(gohm).safeTransfer(
                    IController(controller).treasury(),
                    _gohm
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
        return "StrategyJoeFraxgOhm";
    }
}