// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import {IAurigamiRewarder, IAurigamiController} from "../../../interfaces/aurigami.sol";

contract StrategyPlyNearLP is StrategyBase {
    // Token addresses
    address public constant ply = 0x09C9D464b58d96837f8d8b6f4d9fE4aD408d3A4f;
    address public constant plynearlp = 0x044b6B0CD3Bb13D2b9057781Df4459C66781dCe7;

    address public constant rewards = 0xC9A848AC73e378516B16E4EeBBa5ef6aFbC0BBc2;
    address public constant auriController = 0x817af6cfAF35BdC1A634d6cC94eE9e4c68369Aeb;

    // WETH/<token1> pair
    address public token0;
    address public token1;

    // How much PLY to keep?
    uint256 public keepPLY = 1000;
    uint256 public constant keepPLYMax = 10000;

    uint256 public constant poolId = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(plynearlp, _governance, _strategist, _controller, _timelock) {
        token0 = IUniswapV2Pair(want).token0();
        token1 = IUniswapV2Pair(want).token1();

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(rewards, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , ) = IAurigamiRewarder(rewards).getUserInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256[] memory pendingRewards = IAurigamiRewarder(rewards).pendingRewards(poolId, address(this));

        // Only 5 percent immediately claimable
        uint256 pendingPly = pendingRewards[0].mul(5).div(100);

        return pendingPly;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IAurigamiRewarder(rewards).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IAurigamiRewarder(rewards).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepPLY(uint256 _keepPLY) external {
        require(msg.sender == timelock, "!timelock");
        keepPLY = _keepPLY;
    }

    function harvest() public override {
        harvestOne();
        harvestTwo();
        harvestThree();
        harvestFour();
    }

    function harvestOne() public {
        // Collect PLY tokens
        IAurigamiController(auriController).claimReward(0, address(this));
        IAurigamiRewarder(rewards).harvest(address(this), poolId, uint256(-1));

        uint256 _ply = IERC20(ply).balanceOf(address(this));
        if (_ply == 0) return;
        uint256 _keepPLY = _ply.mul(keepPLY).div(keepPLYMax);

        IERC20(ply).safeTransfer(IController(controller).treasury(), _keepPLY);
    }

    function harvestTwo() public {
        uint256 _ply = IERC20(ply).balanceOf(address(this));

        address[] memory nearPath = new address[](2);
        nearPath[0] = ply;
        nearPath[1] = near;
        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_ply.div(2), 0, nearPath, address(this), now + 60);
    }

    function harvestThree() public {
        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(sushiRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).safeTransfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }
    }

    function harvestFour() public {
        deposit();
    }

    function getName() external pure override returns (string memory) {
        return "StrategyPlyNearLP";
    }
}
