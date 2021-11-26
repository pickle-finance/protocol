// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxCraftLp is StrategyJoeRushFarmBase {

    uint256 public avax_craft_poolId = 20;

    address public joe_avax_craft_lp = 0x86D1b1Ab4812a104BC1Ea1FbD07809DE636E6C6b;
    address public craft = 0x8aE8be25C23833e0A01Aa200403e826F611f9CD2;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_craft_poolId,
            joe_avax_craft_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}


     function _takeFeeCraftToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = craft;
        path[1] = wavax;
        path[2] = snob;
        IERC20(craft).safeApprove(joeRouter, 0);
        IERC20(craft).safeApprove(joeRouter, _keep);
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
        uint256 _avax = address(this).balance;              // get balance of native Avax
        if (_avax > 0) {                                    // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _craft = IERC20(craft).balanceOf(address(this));   //get balance of CRA Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of Wavax
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_craft > 0) {
            uint256 _keep2 = _craft.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeCraftToSnob(_keep2);
            }
            
            _craft = IERC20(craft).balanceOf(address(this));
          
        }

        //in the case that there are craft and Avax Rewards swap half craft for wavax and  1/2 wavax for craft using prior balances
        if (_craft > 0 && _wavax > 0){
            IERC20(craft).safeApprove(joeRouter, 0);
            IERC20(craft).safeApprove(joeRouter, _craft.div(2));   
            _swapTraderJoe(craft, wavax, _craft.div(2));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, craft, _wavax.div(2)); 
        }

        //In the case of Craft Rewards and no Avax rewards, swap craft for wavax
        if(_craft > 0 && _wavax ==0){
            IERC20(craft).safeApprove(joeRouter, 0);
            IERC20(craft).safeApprove(joeRouter, _craft.div(2));   
            _swapTraderJoe(craft, wavax, _craft.div(2));
        }

        //in the case of Avax Rewards and no craft rewards, swap wavax for craft
        if(_wavax > 0 && _craft ==0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, craft, _wavax.div(2)); 
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
            _swapTraderJoe(joe, craft, _joe.div(2));
        }

        // Adds in liquidity for AVAX/CRAFT
        _wavax = IERC20(wavax).balanceOf(address(this));
        _craft = IERC20(craft).balanceOf(address(this));

        if (_wavax > 0 && _craft > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(craft).safeApprove(joeRouter, 0);
            IERC20(craft).safeApprove(joeRouter, _craft);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                craft,
                _wavax,
                _craft,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _craft = IERC20(craft).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_craft > 0){
                IERC20(craft).safeTransfer(
                    IController(controller).treasury(),
                    _craft
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxCraftLp";
    }
}
