
pragma solidity ^0.6.7;

import "./pefierc20.sol";
import "./strategy-pefi-base-lp.sol";

contract PenguinStrategyPefiAvaxPefi is PefiStrategyForLP {

    uint public xPefiPerShare; //stores cumulative xPEFI per share, scaled up by 1e18
    uint public NEST_STAKING_BIPS; //share of rewards sent to the nest on behalf of users
    mapping(address=>uint) public xPefiDebt; //pending xPEFI for any address is (its balance * xPefiPerShare) - (its xPefiDebt)


    // Variables to initialize constructor deployment
    // String memory _name = "PefiComp_PEFI-AVAX-LP-Pefi";
    // address depositToken =  0x494Dd9f783dAF777D3fb4303da4de795953592d0;
    // address rewardToken = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;
    // address stakingContract = 0x8AC8ED5839ba269Be2619FfeB3507baB6275C257;
    // address router = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    // address poolCreator = 0x2510547e292590E93E3F48787A5F2E26c267F6FF;
    // address nest = 0xD79A36056c271B988C5F1953e664E61416A9820F;
    // address dev = 0x2510547e292590E93E3F48787A5F2E26c267F6FF;
    // address alternate = 0x9694695dA8482906B86dB232Bfa9F95785414e0A;
    // uint _pid = 0;
    // uint _minTokensToReinvest = 1000000000000000000;

    // uint POOL_CREATOR_FEE_BIPS = 100;
    // uint NEST_FEE_BIPS = 200;
    // uint DEV_FEE_BIPS = 180;
    // uint ALTERNATE_FEE_BIPS = 0;
    // uint[4] memory _initFeeStructure, //pool creator, nest, dev, alternate ;
    // address[] memory _pathRewardToToken0 = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    // address[] memory _pathRewardToToken1 = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;
    // address _pefiGlobalVariables = 0x37Bf157A569e4c0F478d0d2864af9a49be8e0797;
    // bool _USE_GLOBAL_PEFI_VARIABLES = false;





    event StakedPEFI(uint amountPefiSentToNest);
    event ClaimedxPEFI(address indexed account, uint amount);
    event NestStakingBipsChanged(uint oldNEST_STAKING_BIPS, uint newNEST_STAKING_BIPS);


    constructor(
        string memory _name,
        address[8] memory _initAddressArray, //depositToken, rewardToken, stakingContract, router, poolCreator, nest, dev, alternate
        uint _pid,
        uint _minTokensToReinvest,
        uint[4] memory _initFeeStructure, //pool creator, nest, dev, alternate
        address[] memory _pathRewardToToken0,
        address[] memory _pathRewardToToken1,
        address _pefiGlobalVariables,
        bool _USE_GLOBAL_PEFI_VARIABLES
    )
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
    function deposit(uint amount) external override {
        claimXPEFI(msg.sender);
        _deposit(msg.sender, amount);
        xPefiDebt[msg.sender] = (xPefiPerShare * balances[msg.sender]);
    }

    function withdraw(uint amount) external override {
        claimXPEFI(msg.sender);
        uint depositTokenAmount = getDepositTokensForShares(amount);
        if (depositTokenAmount > 0) {
            _withdrawDepositTokens(depositTokenAmount);
            (,,,, uint withdrawFeeBP) = IPenguinChef(stakingContract).poolInfo(PID);
            uint withdrawFee = ((depositTokenAmount * withdrawFeeBP) / BIPS_DIVISOR);
            require(depositToken.transfer(msg.sender, (depositTokenAmount - withdrawFee)), "PenguinStrategyForIgloos::withdraw");
            _burn(msg.sender, amount);
            totalDeposits -= depositTokenAmount;
            emit Withdraw(msg.sender, depositTokenAmount);
        }
        xPefiDebt[msg.sender] = (xPefiPerShare * balances[msg.sender]);
    }

    function checkReward() public override view returns (uint) {
        uint pendingReward = IPenguinChef(stakingContract).pendingPEFI(PID, address(this));
        uint contractBalance = rewardToken.balanceOf(address(this));
        return (pendingReward + contractBalance);
    }

    /**
    * @notice Estimate recoverable balance after withdraw fee
    * @return deposit tokens after withdraw fee
    */
    function estimateDeployedBalance() external view returns (uint) {
        (uint depositBalance, ) = IMasterChef(stakingContract).userInfo(PID, address(this));
        (,,,, uint withdrawFeeBP) = IPenguinChef(stakingContract).poolInfo(PID);
        uint withdrawFee = ((depositBalance * withdrawFeeBP) / BIPS_DIVISOR);
        return (depositBalance - withdrawFee);
    }

    /**
    * @notice Reinvest rewards from staking contract to deposit tokens
    * @dev Reverts if the expected amount of tokens are not returned from `stakingContract`
    * @param amount deposit tokens to reinvest
    */
    function _reinvest(uint amount) internal override {
        IMasterChef(stakingContract).deposit(PID, 0);    

        uint devFee = (amount * DEV_FEE_BIPS()) / BIPS_DIVISOR;
        if (devFee > 0) {
            require(rewardToken.transfer(devAddress(), devFee), "PefiStrategyForLP::_reinvest, dev");
        }   

        uint nestFee = (amount * NEST_FEE_BIPS()) / BIPS_DIVISOR;
        if (nestFee > 0) {
            require(rewardToken.transfer(nestAddress(), nestFee), "PefiStrategyForLP::_reinvest, nest");
        }   

        uint poolCreatorFee = (amount * POOL_CREATOR_FEE_BIPS()) / BIPS_DIVISOR;
        if (poolCreatorFee > 0) {
            require(rewardToken.transfer(poolCreatorAddress, poolCreatorFee), "PefiStrategyForLP::_reinvest, poolCreator");
        }

        uint alternateFee = (amount * ALTERNATE_FEE_BIPS()) / BIPS_DIVISOR;
        if (alternateFee > 0) {
            require(rewardToken.transfer(alternateAddress(), alternateFee), "PefiStrategyForLP::_reinvest, alternate");
        }

        uint remainingAmount = (amount - (devFee + nestFee + poolCreatorFee + alternateFee));
        uint toNest = remainingAmount * NEST_STAKING_BIPS / BIPS_DIVISOR;
        uint toDepositTokens = remainingAmount - toNest;

        if (toNest > 0) {
            _depositToNest(toNest);
        }

        if (toDepositTokens > 0) {
            uint depositTokenAmount = _convertRewardTokensToDepositTokens(toDepositTokens);
            _stakeDepositTokens(depositTokenAmount);
            totalDeposits += depositTokenAmount; 
        }   

        emit Reinvest(totalDeposits, totalSupply);
    }

    //deposits amount of PEFI to the nest and accounts for it
    function _depositToNest(uint amountPEFI) internal {
        uint xPefiBefore = XPEFI(nestAddress()).balanceOf(address(this));
        rewardToken.approve(nestAddress(), amountPEFI);
        XPEFI(nestAddress()).enter(amountPEFI);
        uint xPefiAfter = XPEFI(nestAddress()).balanceOf(address(this));
        _updateXPefiPerShare(xPefiAfter - xPefiBefore);
        emit StakedPEFI(amountPEFI);
    }

    //updates the value of xPefiPerShare whenever PEFI is sent to the nest
    function _updateXPefiPerShare(uint newXPefi) internal {
        if (totalSupply > 0) {
            xPefiPerShare += ((newXPefi * 1e18) / totalSupply);
        }
    }

    function pendingXPefi(address user) public view returns(uint) {
        return((xPefiPerShare * balances[user] - xPefiDebt[user]) / 1e18);
    }

    function claimXPEFI(address user) public {
        uint amountPending = pendingXPefi(user);
        if (amountPending > 0) {
            xPefiDebt[user] = (xPefiPerShare * balances[user]);
            XPEFI(nestAddress()).transfer(user, amountPending);
            ClaimedxPEFI(user, amountPending);
        }
    }

    function updateNestStakingBips(uint newNEST_STAKING_BIPS) public onlyOwner {
        require(newNEST_STAKING_BIPS <= BIPS_DIVISOR, "PefiStrategyForLP::setNEST_STAKING_BIPS");
        emit NestStakingBipsChanged(NEST_STAKING_BIPS, newNEST_STAKING_BIPS);
        NEST_STAKING_BIPS = newNEST_STAKING_BIPS;
    }

}