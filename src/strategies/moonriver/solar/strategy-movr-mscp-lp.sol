// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-baseV2.sol";

contract StrategyMscpMovrLp is StrategySolarFarmBaseV2 {
    uint256 public movr_mscp_poolId = 3;

    // Token addresses
    address public mscp_movr_lp = 0x4FC513c121A3F1cFA63Bff4c96bA8345A7b1B688;
    address public mscp = 0x5c22ba65F65ADfFADFc0947382f2E7C286A0Fe45;
    address public cws = 0x6fc9651f45B262AE6338a701D563Ab118B1eC0Ce;

    address public solarChefV2 = 0x0329867a8c457e9F75e25b0685011291CD30904F;

    // How much MOVR tokens to keep?
    uint256 public keepMOVR = 1000;
    uint256 public constant keepMOVRMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBaseV2(
            mscp,
            movr,
            movr_mscp_poolId,
            mscp_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        solarChef = solarChefV2;
    }

    // **** State Mutations ****

    function setKeepMOVR(uint256 _keepMOVR) external {
        require(msg.sender == timelock, "!timelock");
        keepMOVR = _keepMOVR;
    }

    function harvest() public override onlyBenevolent {
        // Collects SOLAR tokens
        ISolarChef(solarChef).deposit(poolId, 0);
        uint256 _solar = IERC20(solar).balanceOf(address(this));
        uint256 _cws = IERC20(cws).balanceOf(address(this));
        uint256 _mscp = IERC20(mscp).balanceOf(address(this));

        if (_solar > 0) {
            _swapSushiswap(solar, movr, _solar);
        }

        if (_cws > 0) {
            _swapSushiswap(cws, movr, _cws);
        }

        // if (_mscp > 0) {
        //     _swapSushiswap(mscp, movr, _mscp);
        // }

        uint256 _movr = IERC20(movr).balanceOf(address(this));
        if (_movr > 0) {
            uint256 _keepMOVR = _movr.mul(keepMOVR).div(keepMOVRMax);

            IERC20(movr).safeTransfer(
                IController(controller).treasury(),
                _keepMOVR
            );

            uint256 _swap = (_movr.sub(_keepMOVR)).div(2);

            //Swap half MOVR for MSCP
            _swapSushiswap(movr, mscp, _swap);
        }

        // Adds in liquidity for movr/mscp
        _movr = IERC20(movr).balanceOf(address(this));
        _mscp = IERC20(mscp).balanceOf(address(this));

        if (_movr > 0 && _mscp > 0) {
            IERC20(movr).safeApprove(sushiRouter, 0);
            IERC20(movr).safeApprove(sushiRouter, _movr);
            IERC20(mscp).safeApprove(sushiRouter, 0);
            IERC20(mscp).safeApprove(sushiRouter, _mscp);

            UniswapRouterV2(sushiRouter).addLiquidity(
                mscp,
                movr,
                _mscp,
                _movr,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(mscp).transfer(
                IController(controller).treasury(),
                IERC20(mscp).balanceOf(address(this))
            );
            IERC20(movr).safeTransfer(
                IController(controller).treasury(),
                IERC20(movr).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMscpMovrLp";
    }
}
