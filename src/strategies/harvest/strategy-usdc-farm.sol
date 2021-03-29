// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/controller.sol";

import "../strategy-base.sol";

contract StrategyFarmUsdcV1 is StrategyBase {
    address
        public constant usdcVault = 0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE;
    address
        public constant staking = 0x4F7c28cCb0F1Dbd1388209C67eEc234273C878Bd;

    address 
        public constant farm = 0xa0246c9032bC3A600820415aE600c6388619A14D;

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
        return "StrategyHarvestUsdcV1";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        INoMintRewardPool(staking).getReward();
        // FARM -> Want(usdc)
        uint256 _farm = IERC20(farm).balanceOf(address(this));
        if (_farm > 0) {
            _swapUniswap(farm, want, _farm);
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
        uint256 _shares = balanceOfPool().div(amount).mul(_ppfs);
        IVault(usdcVault).withdraw(_shares);
        return _amount;
    }
}
