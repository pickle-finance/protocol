// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/solar-chefv2.sol";
import "../../interfaces/weth.sol";

abstract contract StrategySolarFarmBaseV3 is StrategyBase {
    // Token addresses
    address public constant solar = 0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B;
    address public constant solarChef = 0x0329867a8c457e9F75e25b0685011291CD30904F;

    address public token0;
    address public token1;

    // How much SOLAR tokens to keep?
    uint256 public keepReward = 1000;
    uint256 public constant keepRewardMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
        IERC20(want).safeApprove(solarChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , , ) = ISolarChef(solarChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() public view returns (address[] memory tokens, uint256[] memory amounts) {
        (address[] memory initialTokens, uint256[] memory initialAmounts) = getInitial();

        uint256[] memory indices = validIndices(initialAmounts);
        amounts = new uint256[](indices.length);
        tokens = new address[](indices.length);

        // Populate return arrays with known indices
        for (uint256 i = 0; i < indices.length; i++) {
            amounts[i] = initialAmounts[indices[i]];
            tokens[i] = initialTokens[indices[i]];
        }
        return (tokens, amounts);
    }

    function getInitial() public view returns (address[] memory tokens, uint256[] memory amounts) {
        (tokens, , , amounts) = ISolarChef(solarChef).pendingTokens(poolId, address(this));
    }

    function validIndices(uint256[] memory amounts) public view returns (uint256[] memory) {
        uint256 j = 0;
        uint256[] memory indices = new uint256[](getCount(amounts));
        // Get size of non-zero returns for sizing returned arrays
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                indices[j] = i;
                j++;
            }
        }

        uint256[] memory returnIndices = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            returnIndices[i] = indices[i];
        }
        return returnIndices;
    }

    function getCount(uint256[] memory amounts) internal view returns (uint256 count) {
        count = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                count++;
            }
        }
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ISolarChef(solarChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ISolarChef(solarChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepReward(uint256 _keepReward) external {
        require(msg.sender == timelock, "!timelock");
        keepReward = _keepReward;
    }

    // **** State Mutations ****

    function harvest() public virtual override {
        // Collects SOLAR tokens
        ISolarChef(solarChef).deposit(poolId, 0);
        uint256 _solar = IERC20(solar).balanceOf(address(this));

        if (_solar > 0) {
            uint256 _keepReward = _solar.mul(keepReward).div(keepRewardMax);
            IERC20(solar).safeTransfer(IController(controller).treasury(), _keepReward);
            _solar = _solar.sub(_keepReward);
            uint256 toToken0 = _solar.div(2);
            uint256 toToken1 = _solar.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token1], toToken1);
            }
        }

        // Wrap MOVR to WMOVR
        uint256 _native = address(this).balance;
        if (_native > 0) WETH(movr).deposit{value: _native}();

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).safeTransfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        _distributePerformanceFeesAndDeposit();
    }

    receive() external payable {}

    fallback() external payable {}
}
