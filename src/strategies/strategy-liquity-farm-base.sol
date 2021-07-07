// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/liquity-reward.sol";

abstract contract StrategyLiquityFarmBase is StrategyBase {
    // Token addresses
    address public lqty = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address public univ3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // WETH/<token1> pair
    address public token1;

    // How much LQTY tokens to keep?
    uint256 public keepLQTY = 0;
    uint256 public constant keepLQTYMax = 10000;

    address public rewards;

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
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        rewards = _rewards;
        token1 = _token1;

        IERC20(lqty).safeApprove(univ2Router2, uint256(-1));
        IERC20(weth).safeApprove(univ2Router2, uint256(-1));
        if (token1 != lqty) {
            IERC20(token1).safeApprove(univ2Router2, uint256(-1));
        }
    }

    // **** Setters ****

    function setKeepLQTY(uint256 _keepLQTY) external {
        require(msg.sender == timelock, "!timelock");
        keepLQTY = _keepLQTY;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects LQTY tokens
        ILiquityFarmReward(rewards).claimReward();
        uint256 _lqty = IERC20(lqty).balanceOf(address(this));
        if (_lqty > 0) {
            // 10% is locked up for future gov
            uint256 _keepLQTY = _lqty.mul(keepLQTY).div(keepLQTYMax);
            IERC20(lqty).safeTransfer(
                IController(controller).treasury(),
                _keepLQTY
            );
            _swapUniswap(lqty, weth, _lqty.sub(_keepLQTY));
        }

        // Swap half WETH for DAI
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapUniswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/DAI
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back UNI LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public view override returns (uint256) {
        return ILiquityFarmReward(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return ILiquityFarmReward(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            ILiquityFarmReward(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILiquityFarmReward(rewards).withdraw(_amount);
        return _amount;
    }

    function _swapUniswapV3(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        UniswapRouterV3(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}
