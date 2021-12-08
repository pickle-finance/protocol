// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxMeadLp is StrategyJoeRushFarmBase {

    uint256 public avax_mead_poolId = ;

    address public joe_avax_mead_lp = 0xb97F23A9e289B5F5e8732b6e20df087977AcC434;
    address public mead = 0x245C2591403e182e41d7A851eab53B01854844CE;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_mead_poolId,
            joe_avax_mead_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}


     function _takeFeeMeadToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = mead;
        path[1] = wavax;
        path[2] = snob;
        IERC20(mead).safeApprove(joeRouter, 0);
        IERC20(mead).safeApprove(joeRouter, _keep);
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
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Rewards tokens (JOE & AVAX)
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        //Take Avax Rewards    
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            // convert Avax Rewards
            // MEAD: 3% Reflective 1% Burn
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.mul(100).div(196));   
            _swapTraderJoe(wavax, mead, _wavax.mul(100).div(196));

        }
        
        // Take Joe Rewards
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
            // MEAD: 3% Reflective 1% Burn
            _swapTraderJoe(joe, wavax, _joe.mul(96).div(196));
            _swapTraderJoe(joe, mead, _joe.mul(100).div(196));
        }

        // Adds in liquidity for AVAX/MEAD
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _mead = IERC20(mead).balanceOf(address(this));

        if (_wavax > 0 && _mead > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(mead).safeApprove(joeRouter, 0);
            IERC20(mead).safeApprove(joeRouter, _mead);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                mead,
                _wavax,
                _mead,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _mead = IERC20(mead).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_mead > 0){
                IERC20(mead).safeTransfer(
                    IController(controller).treasury(),
                    _mead
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMeadLp";
    }
}