// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxPtp is StrategyJoeRushFarmBase {

    uint256 public avax_ptp_poolId = 28;

    address public joe_avax_ptp_lp = 0xCDFD91eEa657cc2701117fe9711C9a4F61FEED23;
    address public ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_ptp_poolId,
            joe_avax_ptp_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeePtpToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = ptp;
        path[1] = wavax;
        path[2] = snob;
        IERC20(ptp).safeApprove(joeRouter, 0);
        IERC20(ptp).safeApprove(joeRouter, _keep);
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
        
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));      //get balance of PTP Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

         if (_ptp > 0) {
            uint256 _keep2 = _ptp.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeePtpToSnob(_keep2);
            }
            
            _ptp = IERC20(ptp).balanceOf(address(this));
        }

        // In the case of PTP Rewards, swap PTP for WAVAX
        if (_ptp > 0){
            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp.div(2));   
            _swapTraderJoe(ptp, wavax, _ptp.div(2));
        }

        // In the case of AVAX Rewards, swap WAVAX for PTP
        if (_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ptp, _wavax.div(2)); 
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
            _swapTraderJoe(joe, ptp, _joe.div(2));
        }

        // Adds in liquidity for AVAX/PTP
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ptp = IERC20(ptp).balanceOf(address(this));

        if (_wavax > 0 && _ptp > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ptp,
                _wavax,
                _ptp,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ptp = IERC20(ptp).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_ptp > 0){
                IERC20(ptp).safeTransfer(
                    IController(controller).treasury(),
                    _ptp
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
        return "StrategyJoeAvaxPtp";
    }
}