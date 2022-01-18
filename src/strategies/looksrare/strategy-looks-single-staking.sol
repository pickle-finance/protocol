// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/looks-staking.sol";

contract StrategyLooksStaking is StrategyBase {
    // Token addresses
    address public constant looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    address public constant looksStaking =
        0xBcD7254A1D759EFA08eC7c3291B2E85c5dCC12ce;
    address public constant looksDistributor =
        0x465A790B428268196865a3AE2648481ad7e0d3b1;

    // How much WETH tokens to keep?
    uint256 public keepWETH = 2000;
    uint256 public constant keepWETHMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(looks, _governance, _strategist, _controller, _timelock)
    {}

    // This method for calculating share price is used because the 
    // Looks contract factors in pending rewards
    function calculateSharePrice() public view returns (uint256) {
        (uint256 totalLooks, ) = ILooksDistributor(looksDistributor).userInfo(
            looksStaking
        );

        uint256 totalShares = ILooksStaking(looksStaking).totalShares();
        return totalLooks.mul(1e18).div(totalShares);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 shares, , ) = ILooksStaking(looksStaking).userInfo(
            address(this)
        );

        return shares.mul(calculateSharePrice()).div(1e18);
    }

    function getHarvestable() external view returns (uint256) {
        return
            ILooksStaking(looksStaking).calculatePendingRewards(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(looksStaking, 0);
            IERC20(want).safeApprove(looksStaking, _want);
            ILooksStaking(looksStaking).deposit(_want, false);
        }
    }

    // _amount is in terms of LOOKS, need to convert to shares
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 sharePrice = ILooksStaking(looksStaking)
            .calculateSharePriceInLOOKS();

        // Get withdrawal amount in terms of shares
        uint256 _withdrawalShares = _amount.mul(1e18).div(sharePrice);
        ILooksStaking(looksStaking).withdraw(_withdrawalShares, false);

        return _withdrawalShares.mul(1e18).div(sharePrice);
    }

    function setKeepWETH(uint256 _keepWETH) external {
        require(msg.sender == timelock, "!timelock");
        keepWETH = _keepWETH;
    }

    function harvest() public override onlyBenevolent {
        // Collects WETH tokens
        ILooksStaking(looksStaking).harvest();

        uint256 _weth = IERC20(weth).balanceOf(address(this));

        // Swap all WETH to LOOKS
        if (_weth > 0) {
            uint256 _keepWETH = _weth.mul(keepWETH).div(keepWETHMax);
            IERC20(weth).safeTransfer(
                IController(controller).treasury(),
                _keepWETH
            );
            _weth = IERC20(weth).balanceOf(address(this));

            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            _swapUniswap(weth, looks, _weth);
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLooksStaking";
    }
}
