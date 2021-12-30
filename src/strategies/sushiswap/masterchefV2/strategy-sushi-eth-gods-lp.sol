// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthVegaLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_gods_poolId = 26;

    address public sushi_eth_gods_lp =
        0x295685c8FE08D8192981d21Ea1fe856a07443920;
    address public gods = 0xccC8cb5229B0ac8069C51fd58367Fd1e622aFD97;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_gods_poolId,
            sushi_eth_gods_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and GODS tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _gods = IERC20(gods).balanceOf(address(this));
        if (_gods > 0) {
            uint256 _amount = _gods.div(2);
            IERC20(gods).safeApprove(sushiRouter, 0);
            IERC20(gods).safeApprove(sushiRouter, _amount);
            _swapSushiswap(gods, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, gods, _amount);
        }

        // Adds in liquidity for WETH/GODS
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _gods = IERC20(gods).balanceOf(address(this));

        if (_weth > 0 && _gods > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(gods).safeApprove(sushiRouter, 0);
            IERC20(gods).safeApprove(sushiRouter, _gods);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                gods,
                _weth,
                _gods,
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
            IERC20(gods).safeTransfer(
                IController(controller).treasury(),
                IERC20(gods).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthVegaLp";
    }
}
