// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-pefi-base.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/masterchefIgloos.sol";

abstract contract PefiStrategyForLP is PefiStrategy {
    IRouter public router;
    address public stakingContract;
    address public token0;
    address public token1;
    address[] pathRewardToToken0;
    address[] pathRewardToToken1;
    uint256 public PID;

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
    ) public {
        name = _name;
        depositToken = IPair(_initAddressArray[0]);
        rewardToken = IERC20(_initAddressArray[1]);
        stakingContract = _initAddressArray[2];
        router = IRouter(_initAddressArray[3]);
        updatePoolCreatorAddress(_initAddressArray[4]);
        updateNestAddress(_initAddressArray[5]);
        updateDevAddress(_initAddressArray[6]);
        updateAlternateAddress(_initAddressArray[7]);
        PID = _pid;
        pathRewardToToken0 = _pathRewardToToken0;
        pathRewardToToken1 = _pathRewardToToken1;
        token0 = _pathRewardToToken0[_pathRewardToToken0.length - 1];
        token1 = _pathRewardToToken1[_pathRewardToToken1.length - 1];
        pefiGlobalVariableContract = PenguinStrategyGlobalVariables(
            _pefiGlobalVariables
        );
        USE_GLOBAL_PEFI_VARIABLES = _USE_GLOBAL_PEFI_VARIABLES;
        setAllowances();
        updateMinTokensToReinvest(_minTokensToReinvest);
        updateFeeStructure(
            _initFeeStructure[0],
            _initFeeStructure[1],
            _initFeeStructure[2],
            _initFeeStructure[3]
        );
        updateDepositsEnabled(true);

        emit Reinvest(0, 0);
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Restricted to avoid griefing attacks
     */
    function setAllowances() public override onlyOwner {
        depositToken.approve(address(stakingContract), MAX_UINT);
        rewardToken.approve(address(router), MAX_UINT);
        IERC20(IPair(address(depositToken)).token0()).approve(
            address(router),
            MAX_UINT
        );
        IERC20(IPair(address(depositToken)).token1()).approve(
            address(router),
            MAX_UINT
        );
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external virtual override {
        _deposit(msg.sender, amount);
    }

    /**
     * @notice Deposit using Permit
     * @param amount Amount of tokens to deposit
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        depositToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _deposit(msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override {
        _deposit(account, amount);
    }

    function _deposit(address account, uint256 amount) internal {
        require(DEPOSITS_ENABLED == true, "PefiStrategyForLP::_deposit");
        if (MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST > 0) {
            uint256 unclaimedRewards = checkReward();
            if (unclaimedRewards > MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST) {
                _reinvest(unclaimedRewards);
            }
        }
        require(depositToken.transferFrom(msg.sender, address(this), amount));
        _stakeDepositTokens(amount);
        _mint(account, getSharesForDepositTokens(amount));
        totalDeposits += amount;
        emit Deposit(account, amount);
    }

    function _withdrawDepositTokens(uint256 amount) internal {
        require(amount > 0, "PefiStrategyForLP::_withdrawDepositTokens");
        IMasterChef(stakingContract).withdraw(PID, amount);
    }

    function reinvest() external override onlyEOA {
        uint256 unclaimedRewards = checkReward();
        require(
            unclaimedRewards >= MIN_TOKENS_TO_REINVEST,
            "PefiStrategyForLP::reinvest"
        );
        _reinvest(unclaimedRewards);
    }

    function withdraw(uint256 amount) external virtual override {
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        if (depositTokenAmount > 0) {
            _withdrawDepositTokens(depositTokenAmount);
            require(
                depositToken.transfer(msg.sender, depositTokenAmount),
                "transfer failed"
            );
            _burn(msg.sender, amount);
            totalDeposits -= depositTokenAmount;
            emit Withdraw(msg.sender, depositTokenAmount);
        }
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev Reverts if the expected amount of tokens are not returned from `stakingContract`
     * @param amount deposit tokens to reinvest
     */
    function _reinvest(uint256 amount) internal virtual {
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

        uint256 depositTokenAmount = _convertRewardTokensToDepositTokens(
            (amount - (devFee + nestFee + poolCreatorFee + alternateFee))
        );

        _stakeDepositTokens(depositTokenAmount);
        totalDeposits += depositTokenAmount;

        emit Reinvest(totalDeposits, totalSupply);
    }

    function _stakeDepositTokens(uint256 amount) internal {
        require(amount > 0, "PefiStrategyForLP::_stakeDepositTokens");
        IMasterChef(stakingContract).deposit(PID, amount);
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev Always converts through router; there are no price checks enabled
     * @return deposit tokens received
     */
    function _convertRewardTokensToDepositTokens(uint256 amount)
        internal
        returns (uint256)
    {
        uint256 amountIn = (amount / 2);
        require(
            amountIn > 0,
            "PefiStrategyForLP::_convertRewardTokensToDepositTokens"
        );

        // swap to token0
        uint256 amountOutToken0;
        if (pathRewardToToken0.length != 1) {
            uint256[] memory amountsOutToken0 = router.getAmountsOut(
                amountIn,
                pathRewardToToken0
            );
            amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
            router.swapExactTokensForTokens(
                amountIn,
                amountOutToken0,
                pathRewardToToken0,
                address(this),
                block.timestamp
            );
        }

        // swap to token1
        uint256 amountOutToken1;
        if (pathRewardToToken1.length != 1) {
            uint256[] memory amountsOutToken1 = router.getAmountsOut(
                amountIn,
                pathRewardToToken1
            );
            amountOutToken1 = amountsOutToken1[amountsOutToken1.length - 1];
            router.swapExactTokensForTokens(
                amountIn,
                amountOutToken1,
                pathRewardToToken1,
                address(this),
                block.timestamp
            );
        }

        (, , uint256 liquidity) = router.addLiquidity(
            token0,
            token1,
            amountOutToken0,
            amountOutToken1,
            0,
            0,
            address(this),
            block.timestamp
        );

        return liquidity;
    }

    function rescueDeployedFunds(
        uint256 minReturnAmountAccepted,
        bool disableDeposits
    ) external override onlyOwner {
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        IMasterChef(stakingContract).emergencyWithdraw(PID);
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= minReturnAmountAccepted,
            "PefiStrategyForLP::rescueDeployedFunds"
        );
        totalDeposits = balanceAfter;
        emit Reinvest(totalDeposits, totalSupply);
        if (DEPOSITS_ENABLED == true && disableDeposits == true) {
            updateDepositsEnabled(false);
        }
    }
}
