pragma solidity ^0.6.7;

import "../../../../lib/safe-math.sol";
import "../../../../lib/erc20.sol";

import "../../hevm.sol";
import "../../user.sol";
import "../../test-approx.sol";

import "../../../../interfaces/usdt.sol";
import "../../../../interfaces/weth.sol";
import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

contract DSTestDefiBase is DSTestApprox {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address burn = 0x000000000000000000000000000000000000dEaD;

    address eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address cro = 0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23;
    address dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;
    address usdc = 	0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    address wbtc = 0x062E66477Faf219F25D27dCED647BF57C3107d52;

    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    UniswapRouterV2 univ2 = UniswapRouterV2(
        0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae
    );

    IUniswapV2Factory univ2Factory = IUniswapV2Factory(
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32
    );

    uint256 startTime = block.timestamp;

    receive() external payable {}
    fallback () external payable {}

    function _getERC20(address token, uint256 _amount) virtual internal {
        address[] memory path = new address[](2);
        path[0] = wcro;
        path[1] = token;

        uint256[] memory ins = univ2.getAmountsIn(_amount, path);
        uint256 croAmount = ins[0];

        univ2.swapETHForExactTokens{value: croAmount}(
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

    function _getERC20WithMatic(address token, uint256 _maticAmount) virtual internal {
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
