// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./lib/erc20.sol";

import "./interfaces/pangolin.sol";

contract SnowSwap {
    using SafeERC20 for IERC20;

    IPangolinRouter router = IPangolinRouter(
        0x2D99ABD9008Dc933ff5c0CD271B88309593aB921
    );

    address public constant wavax = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    function convertWAVAXPair(
        address fromLP,
        address toLP,
        uint256 value
    ) public {
        IPangolinPair fromPair = IPangolinPair(fromLP);
        IPangolinPair toPair = IPangolinPair(toLP);

        // Only for WAVAX/<TOKEN> pairs
        if (!(fromPair.token0() == wavax || fromPair.token1() == wavax)) {
            revert("!eth-from");
        }
        if (!(toPair.token0() == wavax || toPair.token1() == wavax)) {
            revert("!eth-to");
        }

        // Get non-eth token from pairs
        address _from = fromPair.token0() != wavax
            ? fromPair.token0()
            : fromPair.token1();

        address _to = toPair.token0() != wavax
            ? toPair.token0()
            : toPair.token1();

        // Transfer
        IERC20(fromLP).safeTransferFrom(msg.sender, address(this), value);

        // Remove liquidity
        IERC20(fromLP).safeApprove(address(router), 0);
        IERC20(fromLP).safeApprove(address(router), value);
        router.removeLiquidity(
            fromPair.token0(),
            fromPair.token1(),
            value,
            0,
            0,
            address(this),
            now + 60
        );

        // Convert to target token
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = wavax;
        path[2] = _to;

        IERC20(_from).safeApprove(address(router), 0);
        IERC20(_from).safeApprove(address(router), uint256(-1));
        router.swapExactTokensForTokens(
            IERC20(_from).balanceOf(address(this)),
            0,
            path,
            address(this),
            now + 60
        );

        // Supply liquidity
        IERC20(wavax).safeApprove(address(router), 0);
        IERC20(wavax).safeApprove(address(router), uint256(-1));

        IERC20(_to).safeApprove(address(router), 0);
        IERC20(_to).safeApprove(address(router), uint256(-1));
        router.addLiquidity(
            wavax,
            _to,
            IERC20(wavax).balanceOf(address(this)),
            IERC20(_to).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            now + 60
        );

        // Refund sender any remaining tokens
        IERC20(wavax).safeTransfer(
            msg.sender,
            IERC20(wavax).balanceOf(address(this))
        );
        IERC20(_to).safeTransfer(msg.sender, IERC20(_to).balanceOf(address(this)));
    }
}
