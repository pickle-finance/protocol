// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxIceLp is StrategyJoeRushFarmBase {
    uint256 public avax_ice_poolId = 9;

    address public joe_avax_ice_lp = 0xF8Ba19769AaE90bEF1d6B00aAEE38204Ed48976a;
    address public ice = 0xe0Ce60AF0850bF54072635e66E79Df17082A1109;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_ice_poolId,
            joe_avax_ice_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            uint256 _amount = _joe.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, ice, _amount);
        }

        //Take Avax Rewards    
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
             uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            uint256 _amount2 = _wavax.sub(_keep2).div(2);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }

        //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _amount2);   
            _swapTraderJoe(wavax, ice, _amount2);
        }

        // Adds in liquidity for AVAX/ice
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _ice = IERC20(ice).balanceOf(address(this));

        if (_wavax > 0 && _ice > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ice).safeApprove(joeRouter, 0);
            IERC20(ice).safeApprove(joeRouter, _ice);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ice,
                _wavax,
                _ice,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(ice).safeTransfer(
                IController(controller).treasury(),
                IERC20(ice).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxIceLp";
    }
}