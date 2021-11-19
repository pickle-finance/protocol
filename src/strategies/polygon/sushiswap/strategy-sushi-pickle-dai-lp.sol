// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiPickleDaiLp is StrategySushiFarmBase {
    // Pickle/Dai pool id in MasterChef contract
    uint256 public sushi_pickle_dai_poolId = 37;

    // Token addresses
    address public pickle_dai_slp = 0x57602582eB5e82a197baE4E8b6B80E39abFC94EB;
    address public dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public pickle = 0x2b88aD57897A8b496595925F43048301C37615Da;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            pickle,
            dai,
            sushi_pickle_dai_poolId,
            pickle_dai_slp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiPickleDaiLp";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects SUSHI tokens
        IMiniChefV2(miniChef).harvest(poolId, address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            _swapSushiswap(sushi, weth, _sushi);
        }

        // Collect MATIC tokens
        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            _swapSushiswap(wmatic, weth, _wmatic);
        }

        // Swap half WETH for pickle
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            address[] memory pathPickle = new address[](3);
            pathPickle[0] = weth;
            pathPickle[1] = dai;
            pathPickle[2] = pickle;
            _swapSushiswapWithPath(pathPickle, _weth.div(2));
        }

        // Swap half WETH for dai
        if (_weth > 0) {
            address[] memory pathDai = new address[](2);
            pathDai[0] = weth;
            pathDai[1] = dai;
            _swapSushiswapWithPath(pathDai, _weth.div(2));
        }

        // Adds in liquidity for token0/token1
        uint256 _pickle = IERC20(pickle).balanceOf(address(this));
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_pickle > 0 && _dai > 0) {
            IERC20(pickle).safeApprove(sushiRouter, 0);
            IERC20(pickle).safeApprove(sushiRouter, _pickle);
            IERC20(dai).safeApprove(sushiRouter, 0);
            IERC20(dai).safeApprove(sushiRouter, _dai);

            UniswapRouterV2(sushiRouter).addLiquidity(
                pickle,
                dai,
                _pickle,
                _dai,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(pickle).transfer(
                IController(controller).treasury(),
                IERC20(pickle).balanceOf(address(this))
            );
            IERC20(dai).safeTransfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
            );
        }

        // We want to get back SUSHI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
