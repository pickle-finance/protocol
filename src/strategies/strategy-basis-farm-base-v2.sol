// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

interface IBasisStaking {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claimReward() external;
    function balanceOf(uint256 _pid, address _owner) external view returns(uint256);
    function rewardEarned(uint256 _pid, address _target) external view returns(uint256);
}

abstract contract StrategyBasisFarmBaseV2 is StrategyBase {
    // Token addresses
    address public bas = 0x106538CC16F938776c7c180186975BCA23875287; // BAS v2
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // DAI/<token1> pair
    address public token1;

    // How much BAS tokens to keep?
    uint256 public keepBAS = 0;
    uint256 public constant keepBASMax = 10000;

    uint256 public pid;
    address public rewards = 0x7E7aE8923876955d6Dcb7285c04065A1B9d6ED8c; // Basis V2 Staking

    constructor(
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        token1 = _token1;
        pid = _poolId;

        IERC20(bas).approve(univ2Router2, uint256(-1));
        IERC20(dai).approve(univ2Router2, uint256(-1));
        IERC20(token1).approve(univ2Router2, uint256(-1));
        IERC20(_lp).approve(rewards, uint256(-1));
    }

    function balanceOfPool() public override view returns (uint256) {
        return IBasisStaking(rewards).balanceOf(pid, address(this));
    }

    // Used only for displaying purpose
    function getHarvestable() external view returns (uint256) {
        return IBasisStaking(rewards).rewardEarned(pid, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IBasisStaking(rewards).deposit(pid, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBasisStaking(rewards).withdraw(pid, _amount);
        return _amount;
    }

    function setKeepBAS(uint256 _keepBAS) external {
        require(msg.sender == timelock, "!timelock");
        keepBAS = _keepBAS;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.
        address[] memory path = new address[](2);

        // Collects BAS tokens
        IBasisStaking(rewards).claimReward();
        uint256 _bas = IERC20(bas).balanceOf(address(this));
        if (_bas > 0) {
            // 10% is locked up for future gov
            uint256 _keepBAS = _bas.mul(keepBAS).div(keepBASMax);
            IERC20(bas).safeTransfer(
                IController(controller).treasury(),
                _keepBAS
            );
            path[0] = bas;
            path[1] = dai;
            _swapUniswapWithPath(path, _bas.sub(_keepBAS));
        }

        // Swap half DAI for token
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            path[0] = dai;
            path[1] = token1;
            _swapUniswapWithPath(path, _dai.div(2));
        }

        // Adds in liquidity for DAI/Token
        _dai = IERC20(dai).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_dai > 0 && _token1 > 0) {
            UniswapRouterV2(univ2Router2).addLiquidity(
                dai,
                token1,
                _dai,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );
        }

        // We want to get back BAS LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
