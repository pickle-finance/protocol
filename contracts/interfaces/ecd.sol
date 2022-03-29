// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IPTPDepositor {
    function deposit(
        uint256 _amount,
        bool _lock,
        address _stakeAddress
    ) external;

    function deposit(uint256 _amount, bool _lock) external;

    function lockIncentive() external view returns (uint256);
}

interface IEcdPtpStaking {
    function multiplier() external view returns (uint256);

    function stake(uint256 amount) external;

    function stakeFor(address depositor, uint256 amount) external;

    function claim() external;

    function claimable(address addr) external view returns (uint256);

    function withdraw(uint256 amountToBeWithdrawn) external;

    function emergencyWithdraw() external;

    function balanceOf(address account) external view returns (uint256);

    function lastUserAdjTimestampReward(address addr)
        external
        view
        returns (uint256);
}

interface IBooster {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(
    uint256 _pid,
    uint256 _amount,
    bool _claim
    ) external;

}

interface IDepositZap {
    function deposit(
        uint256 poolId,
        address pool,
        address token,
        uint256 amount,
        uint256 deadline
    ) external;
}

interface IRewardPool {
    function getReward(address _account, bool _claimExtras) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);
}

interface IMasterChef{

        /* Reads */
    function userInfo(uint256, address) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    function pendingEcd(uint256 _pid, address _user)
        external
        view
        returns (uint256); 

    function withdraw(uint256 pid, uint256 amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function updatePool(uint256 _pid) external;
}

interface IPool {
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

interface MasterChef {
    function deposit(uint256 _pid, uint256 _amount) external; 

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingEcd(uint256 _pid, address _user) external view returns (uint256); 

       /* Reads */
    function userInfo(uint256, address) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );
}