// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IPoolHelper {
    function deposit(uint256 amount) external;

    function balance(address _address) external view returns (uint256); 

    function withdraw(uint256 amount, uint256 minAmount) external; 

    function earned(address token) external view returns (uint256 vtxAmount, uint256 tokenAmount); 

    function getReward() external; 

    function pendingPTP() external view returns (uint256 pendingTokens);

    function depositTokenBalance() external view returns (uint256);
}

interface IMasterChefVTX {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function createRewarder(address _lpToken, address mainRewardToken)
        external
        returns (address);

    // View function to see pending VTXs on frontend.
    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function pendingTokens(
        address _lp,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 pendingVTX,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(address _lp)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(address _lp) external;

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function lock(
        address _lp,
        uint256 _amount,
        uint256 _index,
        bool force
    ) external;

    function unlock(
        address _lp,
        uint256 _amount,
        uint256 _index
    ) external;

    function multiUnlock(
        address _lp,
        uint256[] calldata _amount,
        uint256[] calldata _index
    ) external;

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;

    function multiclaim(address[] calldata _lps, address user_address) external;

    function emergencyWithdraw(address _lp, address sender) external;

    function dev(address _devAddr) external;

    function setDevPercent(uint256 _newDevPercent) external;

    function setTreasuryAddr(address _treasuryAddr) external;

    function setTreasuryPercent(uint256 _newTreasuryPercent) external;

    function setInvestorAddr(address _investorAddr) external;

    function setInvestorPercent(uint256 _newInvestorPercent) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 depositAmount);
}


interface IBaseRewardPool {
    function earned(address _account, address _rewardToken) external view returns (uint256); 

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external returns (bool);
}

interface IxPTP {
     function deposit(uint256 _amount) external;
}