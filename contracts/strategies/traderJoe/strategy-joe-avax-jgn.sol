// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxJgn is StrategyJoeRushFarmBase {

    uint256 public avax_jgn_poolId = 35;

    address public joe_avax_jgn_lp = 0x47898DbF127205Ea2E94a30B5291C9476E36f3bA;
    address public jgn = 0x4e3642603a75528489C2D94f86e9507260d3c5a1;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_jgn_poolId,
            joe_avax_jgn_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeJgnToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = jgn;
        path[1] = wavax;
        path[2] = snob;
        IERC20(jgn).safeApprove(joeRouter, 0);
        IERC20(jgn).safeApprove(joeRouter, _keep);
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
        
        uint256 _jgn = IERC20(jgn).balanceOf(address(this));     //get balance of JGN Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

         if (_jgn > 0) {
            uint256 _keep2 = _jgn.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeJgnToSnob(_keep2);
            }

            _jgn = IERC20(jgn).balanceOf(address(this));
        }

        //In the case of JGN Rewards, swap JGN for WAVAX
        if(_jgn > 0){
            IERC20(jgn).safeApprove(joeRouter, 0);
            IERC20(jgn).safeApprove(joeRouter, _jgn.div(2));   
            _swapTraderJoe(jgn, wavax, _jgn.div(2));
        }

        //in the case of AVAX Rewards, swap WAVAX for JGN
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, jgn, _wavax.div(2)); 
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
            _swapTraderJoe(joe, jgn, _joe.div(2));
        }

        // Adds in liquidity for AVAX/JGN
        _wavax = IERC20(wavax).balanceOf(address(this));
        _jgn = IERC20(jgn).balanceOf(address(this));

        if (_wavax > 0 && _jgn > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(jgn).safeApprove(joeRouter, 0);
            IERC20(jgn).safeApprove(joeRouter, _jgn);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                jgn,
                _wavax,
                _jgn,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _jgn = IERC20(jgn).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_jgn > 0){
                IERC20(jgn).safeTransfer(
                    IController(controller).treasury(),
                    _jgn
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
        return "StrategyJoeAvaxJgn";
    }
}