pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/staking-rewards.sol";

contract StrategyNewoUsdcLp is StrategyBase {
    // Token addresses
    address public constant stakingRewards =
        0x9D4af0f08B300437b4f0d97A1C5c478F1e0A7D3C;
    address public constant newo = 0x1b890fD37Cd50BeA59346fC2f8ddb7cd9F5Fabd5;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public newo_newo_usdc_lp =
        0xB264dC9D22ece51aAa6028C5CBf2738B684560D6;

    // How much NEWO tokens to keep?
    uint256 public keepNEWO = 2000;
    uint256 public constant keepNEWOMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            newo_newo_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(stakingRewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(stakingRewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingRewards, 0);
            IERC20(want).safeApprove(stakingRewards, _want);
            IStakingRewards(stakingRewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(stakingRewards).withdraw(_amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepNEWO(uint256 _keepNEWO) external {
        require(msg.sender == timelock, "!timelock");
        keepNEWO = _keepNEWO;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects NEWO tokens
        IStakingRewards(stakingRewards).getReward();
        uint256 _newo = IERC20(newo).balanceOf(address(this));

        // Swap half NEWO for USDC
        if (_newo > 0) {
            uint256 _keepNEWO = _newo.mul(keepNEWO).div(keepNEWOMax);
            IERC20(newo).safeTransfer(
                IController(controller).treasury(),
                _keepNEWO
            );
            address[] memory path = new address[](2);
            path[0] = newo;
            path[1] = usdc;
            uint256 _swap = (_newo.sub(_keepNEWO)).div(2);
            IERC20(newo).safeApprove(sushiRouter, 0);
            IERC20(newo).safeApprove(sushiRouter, _swap);
            _swapSushiswapWithPath(path, _swap);
        }

        // Adds in liquidity for NEWO/USDC
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        _newo = IERC20(newo).balanceOf(address(this));
        if (_usdc > 0 && _newo > 0) {
            IERC20(usdc).safeApprove(sushiRouter, 0);
            IERC20(usdc).safeApprove(sushiRouter, _usdc);
            IERC20(newo).safeApprove(sushiRouter, 0);
            IERC20(newo).safeApprove(sushiRouter, _newo);

            UniswapRouterV2(sushiRouter).addLiquidity(
                newo,
                usdc,
                _newo,
                _usdc,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdc).transfer(
                IController(controller).treasury(),
                IERC20(usdc).balanceOf(address(this))
            );
            IERC20(newo).safeTransfer(
                IController(controller).treasury(),
                IERC20(newo).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    function getName() external pure override returns (string memory) {
        return "StrategyNewoUsdcLp";
    }
}
