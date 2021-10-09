pragma solidity ^0.6.7;

import "./strategy-base.sol";

abstract contract StrategyDopexFarmBase is StrategyBase {
    address public rewards;
    address public baseToken;

    // Token addresses
    address public dpx = 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55;
    address public rdpx = 0x32Eb7902D4134bf98A28b963D26de779AF92A212;

    // **** Getters ****
    constructor(
        address _baseToken,
        address _rewards,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        rewards = _rewards;
        baseToken = _baseToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        address rewardToken = baseToken == dpx ? rdpx : dpx;

        // Collects DPX and RDPX tokens
        IStakingRewards(rewards).getReward(2);
        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));

        // Sell rewardToken for baseToken and sell half for liquidity
        if (_rewardToken > 0) {
            _swapSushiswap(rewardToken, baseToken, _rewardToken);
        }

        uint256 _baseToken = IERC20(baseToken).balanceOf(address(this));
        if (_baseToken > 0) {
            _swapSushiswap(baseToken, weth, _baseToken.div(2));
        }

        // Adds in liquidity for baseToken/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        _baseToken = IERC20(baseToken).balanceOf(address(this));
        if (_weth > 0 && _baseToken > 0) {
            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                baseToken,
                _weth,
                _baseToken,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).safeTransfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(baseToken).safeTransfer(
                IController(controller).treasury(),
                IERC20(baseToken).balanceOf(address(this))
            );
        }

        // We want to get back baseToken-WETH LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
