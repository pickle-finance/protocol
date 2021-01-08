pragma solidity ^0.6.7;

import "../../lib/safe-math.sol";
import "../../lib/erc20.sol";

import "./hevm.sol";
import "./user.sol";
import "./test-approx.sol";
import "./test-defi-base.sol";

import "../../interfaces/usdt.sol";
import "../../interfaces/weth.sol";
import "../../interfaces/strategy.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";

contract DSTestSushiBase is DSTestDefiBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    UniswapRouterV2 sushiRouter = UniswapRouterV2(
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    );

    IUniswapV2Factory sushiFactory = IUniswapV2Factory(
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
    );

    function _getERC20(address token, uint256 _amount) override internal {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        uint256[] memory ins = sushiRouter.getAmountsIn(_amount, path);
        uint256 ethAmount = ins[0];

        sushiRouter.swapETHForExactTokens{value: ethAmount}(
            _amount,
            path,
            address(this),
            now + 60
        );
    }

    function _getERC20WithPath(address token, uint256 _amount, address[] memory path) override internal {
        uint256[] memory ins = sushiRouter.getAmountsIn(_amount, path);
        uint256 ethAmount = ins[0];

        sushiRouter.swapETHForExactTokens{value: ethAmount}(
            _amount,
            path,
            address(this),
            now + 60
        );
    }

    function _getERC20WithETH(address token, uint256 _ethAmount) override internal {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        sushiRouter.swapExactETHForTokens{value: _ethAmount}(
            0,
            path,
            address(this),
            now + 60
        );
    }

    function _getSLPToken(address lpToken, uint256 _ethAmount) internal {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();

        if (token0 != weth) {
            _getERC20WithETH(token0, _ethAmount.div(2));
        } else {
            WETH(weth).deposit{value: _ethAmount.div(2)}();
        }

        if (token1 != weth) {
            _getERC20WithETH(token1, _ethAmount.div(2));
        } else {
            WETH(weth).deposit{value: _ethAmount.div(2)}();
        }

        IERC20(token0).safeApprove(address(sushiRouter), uint256(0));
        IERC20(token0).safeApprove(address(sushiRouter), uint256(-1));

        IERC20(token1).safeApprove(address(sushiRouter), uint256(0));
        IERC20(token1).safeApprove(address(sushiRouter), uint256(-1));
        sushiRouter.addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            address(this),
            now + 60
        );
    }

    function _getSLPToken(
        address token0,
        address token1,
        uint256 _ethAmount
    ) internal {
        _getSLPToken(sushiFactory.getPair(token0, token1), _ethAmount);
    }
}
