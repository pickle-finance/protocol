// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyMirFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public mir = 0x09a3EcAFa817268f77BE1283176B946C4ff2E608;
    address public ust = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;

    // UST/<token1> pair
    address public token1;

    // How much MIR tokens to keep?
    uint256 public keepMIR = 0;
    uint256 public constant keepMIRMax = 10000;

    // Uniswap swap paths
    address[] public mir_ust_path;
    address[] public ust_token1_path;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;

        mir_ust_path = new address[](2);
        mir_ust_path[0] = mir;
        mir_ust_path[1] = ust;

        ust_token1_path = new address[](2);
        ust_token1_path[0] = ust;
        ust_token1_path[1] = token1;

        IERC20(ust).approve(univ2Router2, uint(-1));
        IERC20(token1).approve(univ2Router2, uint(-1));
    }

    // **** Setters ****

    function setKeepMIR(uint256 _keepMIR) external {
        require(msg.sender == timelock, "!timelock");
        keepMIR = _keepMIR;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects MIR tokens
        IStakingRewards(rewards).getReward();
        uint256 _mir = IERC20(mir).balanceOf(address(this));
        
        // 10% is locked up for future gov
        uint256 _keepMIR = _mir.mul(keepMIR).div(keepMIRMax);
        IERC20(mir).safeTransfer(
            IController(controller).treasury(),
            _keepMIR
        );
        _mir = _mir.sub(_keepMIR);

        if (token1 == mir) {
            _swapUniswapWithPath(mir_ust_path, _mir.div(2));
        } else {
            _swapUniswapWithPath(mir_ust_path, _mir);

            // Swap half UST for token
            _swapUniswapWithPath(ust_token1_path, IERC20(ust).balanceOf(address(this)).div(2));
        }

        // Adds in liquidity for UST/Token
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_ust > 0 && _token1 > 0) {
            UniswapRouterV2(univ2Router2).addLiquidity(
                ust,
                token1,
                _ust,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(ust).safeTransfer(
                IController(controller).treasury(),
                IERC20(ust).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back MIR LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
