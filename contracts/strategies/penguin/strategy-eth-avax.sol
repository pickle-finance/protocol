// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-pefi-base-lp.sol";

contract PenguinStrategyEthAvax is PefiStrategyForLP {
    uint256 public xPefiPerShare; //stores cumulative xPEFI per share, scaled up by 1e18
    uint256 public NEST_STAKING_BIPS; //share of rewards sent to the nest on behalf of users
    mapping(address => uint256) public xPefiDebt; //pending xPEFI for any address is (its balance * xPefiPerShare) - (its xPefiDebt)

    // Variables to initialize constructor deployment
    // String memory _name = "PefiComp_ETH-AVAX-LP-Pefi";
    // address depositToken =  0x1acf1583bebdca21c8025e172d8e8f2817343d65;
    // address rewardToken = 0xe896cdeaac9615145c0ca09c8cd5c25bced6384c;
    // address stakingContract = 0x8ac8ed5839ba269be2619ffeb3507bab6275c257;
    // address router = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    // address poolCreator = 0x2510547e292590e93e3f48787a5f2e26c267f6ff;
    // address nest = 0xd79a36056c271b988c5f1953e664e61416a9820f;
    // address dev = 0x2510547e292590E93E3F48787A5F2E26c267F6FF;
    // address alternate = 0x9694695dA8482906B86dB232Bfa9F95785414e0A;
    // uint _pid = 1;
    // uint _minTokensToReinvest = 1;

    // uint POOL_CREATOR_FEE_BIPS = 1;
    // uint NEST_FEE_BIPS = 200;
    // uint DEV_FEE_BIPS = 280;
    // uint ALTERNATE_FEE_BIPS = 1;
    // uint[4] memory _initFeeStructure, //pool creator, nest, dev, alternate ;
    // address[] memory _pathRewardToToken0 = 0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7;
    // address[] memory _pathRewardToToken1 = 0xf20d962a6c8f70c731bd838a3a388d7d48fa6e15;
    // address _pefiGlobalVariables = 0x37Bf157A569e4c0F478d0d2864af9a49be8e0797;
    // bool _USE_GLOBAL_PEFI_VARIABLES = false;

    event StakedPEFI(uint256 amountPefiSentToNest);
    event ClaimedxPEFI(address indexed account, uint256 amount);
    event NestStakingBipsChanged(
        uint256 oldNEST_STAKING_BIPS,
        uint256 newNEST_STAKING_BIPS
    );

    constructor(
        string memory _name,
        address[8] memory _initAddressArray, //depositToken, rewardToken, stakingContract, router, poolCreator, nest, dev, alternate
        uint256 _pid,
        uint256 _minTokensToReinvest,
        uint256[4] memory _initFeeStructure, //pool creator, nest, dev, alternate
        address[] memory _pathRewardToToken0,
        address[] memory _pathRewardToToken1,
        address _pefiGlobalVariables,
        bool _USE_GLOBAL_PEFI_VARIABLES
    )
        public
        PefiStrategyForLP(
            _name,
            _initAddressArray,
            _pid,
            _minTokensToReinvest,
            _initFeeStructure,
            _pathRewardToToken0,
            _pathRewardToToken1,
            _pefiGlobalVariables,
            _USE_GLOBAL_PEFI_VARIABLES
        )
    {}

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external override {
        claimXPEFI(msg.sender);
        _deposit(msg.sender, amount);
        xPefiDebt[msg.sender] = (xPefiPerShare * balances[msg.sender]);
    }

    function withdraw(uint256 amount) external override {
        claimXPEFI(msg.sender);
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        if (depositTokenAmount > 0) {
            _withdrawDepositTokens(depositTokenAmount);
            (, , , , uint256 withdrawFeeBP) = IPenguinChef(stakingContract)
                .poolInfo(PID);
            uint256 withdrawFee = ((depositTokenAmount * withdrawFeeBP) /
                BIPS_DIVISOR);
            require(
                depositToken.transfer(
                    msg.sender,
                    (depositTokenAmount - withdrawFee)
                ),
                "PenguinStrategyForIgloos::withdraw"
            );
            _burn(msg.sender, amount);
            totalDeposits -= depositTokenAmount;
            emit Withdraw(msg.sender, depositTokenAmount);
        }
        xPefiDebt[msg.sender] = (xPefiPerShare * balances[msg.sender]);
    }

    function checkReward() public view override returns (uint256) {
        uint256 pendingReward = IPenguinChef(stakingContract).pendingPEFI(
            PID,
            address(this)
        );
        uint256 contractBalance = rewardToken.balanceOf(address(this));
        return (pendingReward + contractBalance);
    }

    /**
     * @notice Estimate recoverable balance after withdraw fee
     * @return deposit tokens after withdraw fee
     */
    function estimateDeployedBalance() external view returns (uint256) {
        (uint256 depositBalance, ) = IMasterChef(stakingContract).userInfo(
            PID,
            address(this)
        );
        (, , , , uint256 withdrawFeeBP) = IPenguinChef(stakingContract)
            .poolInfo(PID);
        uint256 withdrawFee = ((depositBalance * withdrawFeeBP) / BIPS_DIVISOR);
        return (depositBalance - withdrawFee);
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev Reverts if the expected amount of tokens are not returned from `stakingContract`
     * @param amount deposit tokens to reinvest
     */
    function _reinvest(uint256 amount) internal override {
        IMasterChef(stakingContract).deposit(PID, 0);

        uint256 devFee = (amount * DEV_FEE_BIPS()) / BIPS_DIVISOR;
        if (devFee > 0) {
            require(
                rewardToken.transfer(devAddress(), devFee),
                "PefiStrategyForLP::_reinvest, dev"
            );
        }

        uint256 nestFee = (amount * NEST_FEE_BIPS()) / BIPS_DIVISOR;
        if (nestFee > 0) {
            require(
                rewardToken.transfer(nestAddress(), nestFee),
                "PefiStrategyForLP::_reinvest, nest"
            );
        }

        uint256 poolCreatorFee = (amount * POOL_CREATOR_FEE_BIPS()) /
            BIPS_DIVISOR;
        if (poolCreatorFee > 0) {
            require(
                rewardToken.transfer(poolCreatorAddress, poolCreatorFee),
                "PefiStrategyForLP::_reinvest, poolCreator"
            );
        }

        uint256 alternateFee = (amount * ALTERNATE_FEE_BIPS()) / BIPS_DIVISOR;
        if (alternateFee > 0) {
            require(
                rewardToken.transfer(alternateAddress(), alternateFee),
                "PefiStrategyForLP::_reinvest, alternate"
            );
        }

        uint256 remainingAmount = (amount -
            (devFee + nestFee + poolCreatorFee + alternateFee));
        uint256 toNest = (remainingAmount * NEST_STAKING_BIPS) / BIPS_DIVISOR;
        uint256 toDepositTokens = remainingAmount - toNest;

        if (toNest > 0) {
            _depositToNest(toNest);
        }

        if (toDepositTokens > 0) {
            uint256 depositTokenAmount = _convertRewardTokensToDepositTokens(
                toDepositTokens
            );
            _stakeDepositTokens(depositTokenAmount);
            totalDeposits += depositTokenAmount;
        }

        emit Reinvest(totalDeposits, totalSupply);
    }

    //deposits amount of PEFI to the nest and accounts for it
    function _depositToNest(uint256 amountPEFI) internal {
        uint256 xPefiBefore = XPEFI(nestAddress()).balanceOf(address(this));
        rewardToken.approve(nestAddress(), amountPEFI);
        XPEFI(nestAddress()).enter(amountPEFI);
        uint256 xPefiAfter = XPEFI(nestAddress()).balanceOf(address(this));
        _updateXPefiPerShare(xPefiAfter - xPefiBefore);
        emit StakedPEFI(amountPEFI);
    }

    //updates the value of xPefiPerShare whenever PEFI is sent to the nest
    function _updateXPefiPerShare(uint256 newXPefi) internal {
        if (totalSupply > 0) {
            xPefiPerShare += ((newXPefi * 1e18) / totalSupply);
        }
    }

    function pendingXPefi(address user) public view returns (uint256) {
        return ((xPefiPerShare * balances[user] - xPefiDebt[user]) / 1e18);
    }

    function claimXPEFI(address user) public {
        uint256 amountPending = pendingXPefi(user);
        if (amountPending > 0) {
            xPefiDebt[user] = (xPefiPerShare * balances[user]);
            XPEFI(nestAddress()).transfer(user, amountPending);
            ClaimedxPEFI(user, amountPending);
        }
    }

    function updateNestStakingBips(uint256 newNEST_STAKING_BIPS)
        public
        onlyOwner
    {
        require(
            newNEST_STAKING_BIPS <= BIPS_DIVISOR,
            "PefiStrategyForLP::setNEST_STAKING_BIPS"
        );
        emit NestStakingBipsChanged(NEST_STAKING_BIPS, newNEST_STAKING_BIPS);
        NEST_STAKING_BIPS = newNEST_STAKING_BIPS;
    }
}
