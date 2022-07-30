// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

struct RouteParams {
    address from;
    address to;
    bool stable;
}
interface ISolidlyRouter {
    

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA,uint256 amountB,uint256 liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        RouteParams[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ISolidlyGauge {
    function earned(address token, address account) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
}
