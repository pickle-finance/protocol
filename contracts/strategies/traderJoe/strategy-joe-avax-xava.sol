// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxXavaLp is StrategyJoeRushFarmBase {
    uint256 public avax_xava_poolId = 2;

    address public joe_avax_xava_lp = 0x72c3438cf1c915EcF5D9F17A6eD346B273d5bF71;
    address public xava = 0xd1c3f94DE7e5B45fa4eDBBA472491a9f4B166FC4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_xava_poolId,
            joe_avax_xava_lp,
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

        //convert Joe Rewards
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, xava, _amount);
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
            _swapTraderJoe(wavax, xava, _amount2);
        }
             

        // Adds in liquidity for AVAX/XAVA
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _xava = IERC20(xava).balanceOf(address(this));

        if (_wavax > 0 && _xava > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(xava).safeApprove(joeRouter, 0);
            IERC20(xava).safeApprove(joeRouter, _xava);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                xava,
                _wavax,
                _xava,
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
            IERC20(xava).safeTransfer(
                IController(controller).treasury(),
                IERC20(xava).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxXavaLp";
    }
}
