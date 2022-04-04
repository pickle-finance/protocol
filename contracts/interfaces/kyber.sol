// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/erc20.sol";

interface IKyber {
    function addLiquidityETH(
        address token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function addLiquidity(
    address tokenA,
    address tokenB,
    address pool,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    uint256[2] calldata vReserveRatioBounds,
    address to,
    uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function getTradeInfo() external view returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint112 _vReserve0,
        uint112 _vReserve1,
        uint256 feeInPrecision
    );

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1);

    /**
   * @dev Deposit tokens to accumulate rewards
   * @param _pid: id of the pool
   * @param _amount: amount of stakeToken to be deposited
   * @param _shouldHarvest: whether to harvest the reward or not
   */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _shouldHarvest
    ) external; 

    /**
   * @dev Get pending rewards of a user from a pool, mostly for front-end
   * @param _pid: id of the pool
   * @param _user: user to check for pending rewards
   */
  function pendingRewards(uint256 _pid, address _user)
    external view
    returns (uint256[] memory rewards);

    /**
    * @dev Return user's info including deposited amount and reward data
    */
    function getUserInfo(uint256 _pid, address _account)
    external
    view
    returns (
        uint256 amount,
        uint256[] memory unclaimedRewards,
        uint256[] memory lastRewardPerShares
    );

    /**
    * @dev Withdraw token (of the sender) from pool, also harvest rewards
    * @param _pid: id of the pool
    * @param _amount: amount of stakeToken to withdraw
    */
    function withdraw(uint256 _pid, uint256 _amount) external;  

    function harvest(uint256 _pid) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IRewardLocker {
    /**
   * @notice Allow a user to vest with specific schedule
   */
    function vestScheduleAtIndices(address token, uint256[] calldata indexes) external returns (uint256);

    function accountVestedBalance(address, address) external returns(uint256);
}

interface IKyberFactory {
    function getPools(IERC20 token0, IERC20 token1) external view returns (address[] memory _tokenPools);
}

interface IDMMPool {
    function kLast() external view returns (uint256);
}

