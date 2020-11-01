// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/barnbridge.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-base.sol";

contract StrategyBondUsdcV1 is StrategyBase {
    address
        public constant staking = 0xb0Fa2BeEe3Cf36a7Ac7E99B885b48538Ab364853;
    address
        public constant yieldfarm = 0xB3F7abF8FA1Df0fF61C5AC38d35e20490419f4bb;

    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public constant bond = 0x0391D2021f89DC339F60Fff84546EA23E337750f;

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
        return IBBStaking(staking).balanceOf(address(this), want);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyBondUsdcV1";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Mass Harvest
        IBBYieldFarm(yieldfarm).massHarvest();

        // Bond -> Want
        uint256 _bond = IERC20(bond).balanceOf(address(this));
        if (_bond > 0) {
            _swapUniswap(bond, want, _bond);
        }

        _distributePerformanceFeesAndDeposit();
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(staking, 0);
            IERC20(want).safeApprove(staking, _want);
            IBBStaking(staking).deposit(want, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        IBBStaking(staking).withdraw(want, _amount);
        return _amount;
    }
}
