pragma solidity ^0.6.7;

import "../../../../lib/safe-math.sol";
import "../../../../lib/erc20.sol";

import "../../hevm.sol";
import "../../user.sol";
import "../../test-approx.sol";

import "../../../../interfaces/usdt.sol";
import "../../../../interfaces/weth.sol";
import "../../../../interfaces/sushi-strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

contract DSTestQuickBase is DSTestApprox {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address pickle = 0x2b88aD57897A8b496595925F43048301C37615Da;
    address burn = 0x000000000000000000000000000000000000dEaD;

    address eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    address wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    UniswapRouterV2 univ2 = UniswapRouterV2(
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
    );

    IUniswapV2Factory univ2Factory = IUniswapV2Factory(
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32
    );

    uint256 startTime = block.timestamp;

    receive() external payable {}
    fallback () external payable {}

    function _getERC20(address token, uint256 _amount) virtual internal {
        address[] memory path = new address[](3);
        path[0] = wmatic;
        path[1] = weth;
        path[2] = token;

        uint256[] memory ins = univ2.getAmountsIn(_amount, path);
        uint256 maticAmount = ins[0];

        univ2.swapETHForExactTokens{value: maticAmount}(
            _amount,
            path,
            address(this),
            now + 60
        );
    }

    function _getERC20WithPath(address token, uint256 _amount, address[] memory path) virtual internal {
        uint256[] memory ins = univ2.getAmountsIn(_amount, path);
        uint256 maticAmount = ins[0];

        univ2.swapETHForExactTokens{value: maticAmount}(
            _amount,
            path,
            address(this),
            now + 60
        );
    }

    function _getTokenWithPath(address token, uint256 _amount, address[] memory path) virtual internal {
        uint256 decimals = ERC20(token).decimals();
        _getERC20WithPath(token, _amount * (10 ** decimals), path);
    }

    function _getERC20WithMatic(address token, uint256 _maticAmount) virtual internal {
        if (token == wmatic) {
            _getWMatic(_maticAmount);
        } else {
            address[] memory path = new address[](2);
            path[0] = wmatic;
            path[1] = token;

            univ2.swapExactETHForTokens{value: _maticAmount}(
                0,
                path,
                address(this),
                now + 60
            );
        }
    }

    function _getWMatic(uint256 _maticAmount) virtual internal {
        WETH(wmatic).deposit{value: _maticAmount}();
    }

    function _getUniV2LPToken(address lpToken, uint256 _maticAmount) internal {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();

        if (token0 != wmatic) {
            _getERC20WithMatic(token0, _maticAmount.div(2));
        } else {
            WETH(wmatic).deposit{value: _maticAmount.div(2)}();
        }

        if (token1 != wmatic) {
            _getERC20WithMatic(token1, _maticAmount.div(2));
        } else {
            WETH(wmatic).deposit{value: _maticAmount.div(2)}();
        }

        IERC20(token0).safeApprove(address(univ2), uint256(0));
        IERC20(token0).safeApprove(address(univ2), uint256(-1));

        IERC20(token1).safeApprove(address(univ2), uint256(0));
        IERC20(token1).safeApprove(address(univ2), uint256(-1));
        univ2.addLiquidity(
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

    function _getUniV2LPToken(
        address token0,
        address token1,
        uint256 _maticAmount
    ) internal {
        _getUniV2LPToken(univ2Factory.getPair(token0, token1), _maticAmount);
    }

    function _getFunctionSig(string memory sig) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    function _getDynamicArray(address payable one)
        internal
        pure
        returns (address payable[] memory)
    {
        address payable[] memory targets = new address payable[](1);
        targets[0] = one;

        return targets;
    }

    function _getDynamicArray(bytes memory one)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory data = new bytes[](1);
        data[0] = one;

        return data;
    }

    function _getDynamicArray(address payable one, address payable two)
        internal
        pure
        returns (address payable[] memory)
    {
        address payable[] memory targets = new address payable[](2);
        targets[0] = one;
        targets[1] = two;

        return targets;
    }

    function _getDynamicArray(bytes memory one, bytes memory two)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory data = new bytes[](2);
        data[0] = one;
        data[1] = two;

        return data;
    }

    function _getDynamicArray(
        address payable one,
        address payable two,
        address payable three
    ) internal pure returns (address payable[] memory) {
        address payable[] memory targets = new address payable[](3);
        targets[0] = one;
        targets[1] = two;
        targets[2] = three;

        return targets;
    }

    function _getDynamicArray(
        bytes memory one,
        bytes memory two,
        bytes memory three
    ) internal pure returns (bytes[] memory) {
        bytes[] memory data = new bytes[](3);
        data[0] = one;
        data[1] = two;
        data[2] = three;

        return data;
    }
}
