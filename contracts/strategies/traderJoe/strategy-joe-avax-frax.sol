// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxFrax is StrategyJoeRushFarmBase {

    uint256 public avax_frax_poolId = 33;

    address public joe_avax_frax_lp = 0x862905a82382Db9405a40DCAa8Ee9e8F4af52C89;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;
    address public fxs = 0x214DB107654fF987AD859F34125307783fC8e387; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_frax_poolId,
            joe_avax_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

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

    function _takeFeeFxsToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = fxs;
        path[1] = wavax;
        path[2] = snob;
        IERC20(fxs).safeApprove(joeRouter, 0);
        IERC20(fxs).safeApprove(joeRouter, _keep);
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

        uint256 _frax = IERC20(frax).balanceOf(address(this));        // get balance of FRAX Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));      //get balance of WAVAX Tokens
        // In the case of WAVAX Rewards, swap WAVAX for FRAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, frax, _wavax.div(2)); 

        }
      
        // In the case of FRAX Rewards, swap FRAX for WAVAX 
        if (_frax > 0) {
            uint256 _keep2 = _frax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeFraxToSnob(_keep2);
            }
            
            _frax = IERC20(frax).balanceOf(address(this));

            IERC20(frax).safeApprove(joeRouter, 0);
            IERC20(frax).safeApprove(joeRouter, _frax.div(2));   
            _swapTraderJoe(frax, wavax, _frax.div(2));
          
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
            _swapTraderJoe(joe, frax, _joe.div(2));
        }

        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_fxs > 0) {
            // 10% is sent to treasury
            uint256 _keep = _fxs.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeFxsToSnob(_keep);
            }

            _fxs = IERC20(fxs).balanceOf(address(this));

            IERC20(fxs).safeApprove(joeRouter, 0);
            IERC20(fxs).safeApprove(joeRouter, _fxs);

            _swapTraderJoe(fxs, wavax, _fxs.div(2));
            _swapTraderJoe(fxs, frax, _fxs.div(2));
        }

        // Adds in liquidity for AVAX/FRAX
        _frax = IERC20(frax).balanceOf(address(this));
        _wavax = IERC20(wavax).balanceOf(address(this));

        if (_frax > 0 && _wavax > 0) {
            IERC20(frax).safeApprove(joeRouter, 0);
            IERC20(frax).safeApprove(joeRouter, _frax);

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IJoeRouter(joeRouter).addLiquidity(
                frax,
                wavax,
                _frax,
                _wavax,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _frax = IERC20(frax).balanceOf(address(this));
            _wavax = IERC20(wavax).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            _fxs = IERC20(fxs).balanceOf(address(this));
            if (_frax > 0){
                IERC20(frax).transfer(
                    IController(controller).treasury(),
                    _frax
                );
            }
            
            if (_wavax > 0){
                IERC20(wavax).safeTransfer(
                    IController(controller).treasury(),
                    _wavax
                );
            } 

            if (_joe > 0){
                IERC20(joe).transfer(
                    IController(controller).treasury(),
                    _joe
                );
            }

            if (_fxs > 0){
                IERC20(fxs).transfer(
                    IController(controller).treasury(),
                    _fxs
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxFrax";
    }
}