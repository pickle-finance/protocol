// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/controller.sol";
import "../../interfaces/force.sol";
import "../strategy-base.sol";

contract StrategyForceUsdcV1 is StrategyBase {
    address
        public constant usdcVault = 0x51654a8c04e97424724E1643d468b51924f6C40F;
    address
        public constant staking = 0x45E60E1bee16Df15f2b87F15F2Acba6F3869462c;

    address 
        public constant force = 0x6807D7f7dF53b7739f6438EABd40Ab8c262c0aa8;

    address
        public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // **** Constructor **** //
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(usdc, _governance, _strategist, _controller, _timelock)
    {}

    // **** View methods ****

    function balanceOfPool() public override view returns (uint256) {
        return INoMintRewardPool(staking).balanceOf(address(this));
    }

    function getName() external override pure returns (string memory) {
        return "StrategyForceUsdcV1";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        INoMintRewardPool(staking).getReward();
        // force -> Want(usdc)
        uint256 _force = IERC20(force).balanceOf(address(this));
        if (_force > 0) {
            _swapUniswap(force, want, _force);
        }
        _distributePerformanceFeesAndDeposit();
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(usdcVault, 0);
            IERC20(want).safeApprove(usdcVault, _want);
            IVault(usdcVault).deposit(_want);
            uint256 _fWant = IVault(usdcVault).balanceOf(address(this));
            IERC20(want).safeApprove(staking,0);
            IERC20(want).safeApprove(staking,_fWant);
            INoMintRewardPool(staking).stake(_fWant);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        INoMintRewardPool(staking).withdraw(_amount);
        uint256 _ppfs = IVault(usdcVault).getPricePerFullShare();
        uint256 _shares = balanceOfPool().div(_amount).mul(_ppfs);
        IVault(usdcVault).withdraw(_shares);
        return _amount;
    }
}
