// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxEgg is StrategyJoeRushFarmBase {

    uint256 public avax_egg_poolId = 32;

    address public joe_avax_egg_lp = 0x3052a75dfD7A9D9B0F81E510E01d3Fe80A9e7ec7;
    address public egg = 0x7761E2338B35bCEB6BdA6ce477EF012bde7aE611;
    address public feed = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_egg_poolId,
            joe_avax_egg_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeEggToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = egg;
        path[1] = wavax;
        path[2] = snob;
        IERC20(egg).safeApprove(joeRouter, 0);
        IERC20(egg).safeApprove(joeRouter, _keep);
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

    function _takeFeeFeedToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = feed;
        path[1] = wavax;
        path[2] = snob;
        IERC20(feed).safeApprove(joeRouter, 0);
        IERC20(feed).safeApprove(joeRouter, _keep);
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
        
        uint256 _egg = IERC20(egg).balanceOf(address(this));      //get balance of EGG Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  //get balance of WAVAX

        // In the case of AVAX Rewards, swap WAVAX for EGG
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, egg, _wavax.div(2)); 

        }

        // In the case of EGG Rewards, swap EGG for WAVAX
        if (_egg > 0) {
            uint256 _keep2 = _egg.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeEggToSnob(_keep2);
            }
            
            _egg = IERC20(egg).balanceOf(address(this));

            IERC20(egg).safeApprove(joeRouter, 0);
            IERC20(egg).safeApprove(joeRouter, _egg.div(2));   
            _swapTraderJoe(egg, wavax, _egg.div(2));
          
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
            _swapTraderJoe(joe, egg, _joe.div(2));
        }

        uint256 _feed = IERC20(feed).balanceOf(address(this));
        if (_feed > 0) {
            // 10% is sent to treasury
            uint256 _keep = _feed.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeFeedToSnob(_keep);
            }

            _feed = IERC20(feed).balanceOf(address(this));

            IERC20(feed).safeApprove(joeRouter, 0);
            IERC20(feed).safeApprove(joeRouter, _feed);

            _swapTraderJoe(feed, wavax, _feed.div(2));
            _swapTraderJoe(feed, egg, _feed.div(2));
        }

        // Adds in liquidity for AVAX/EGG
        _wavax = IERC20(wavax).balanceOf(address(this));
        _egg = IERC20(egg).balanceOf(address(this));

        if (_wavax > 0 && _egg > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(egg).safeApprove(joeRouter, 0);
            IERC20(egg).safeApprove(joeRouter, _egg);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                egg,
                _wavax,
                _egg,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _egg = IERC20(egg).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            _feed = IERC20(feed).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_egg > 0){
                IERC20(egg).safeTransfer(
                    IController(controller).treasury(),
                    _egg
                );
            } 

            if (_joe > 0){
                IERC20(joe).transfer(
                    IController(controller).treasury(),
                    _joe
                );
            }

            if (_feed > 0){
                IERC20(feed).transfer(
                    IController(controller).treasury(),
                    _feed
                );
            } 
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxEgg";
    }
}