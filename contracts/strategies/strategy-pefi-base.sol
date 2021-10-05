// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";
import "../interfaces/pefierc20.sol";
import "../lib/ownable.sol";
import "./penguinStrategyGlobalVariables.sol";

abstract contract PefiStrategy is PefiERC20, Ownable {
    uint256 public totalDeposits;

    IERC20 public depositToken;
    IERC20 public rewardToken;
    address public poolCreatorAddress;
    address public nestAddressLocal;
    address public devAddressLocal;
    address public alternateAddressLocal;

    uint256 public MIN_TOKENS_TO_REINVEST;
    uint256 public MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
    bool public DEPOSITS_ENABLED;

    PenguinStrategyGlobalVariables public pefiGlobalVariableContract;
    bool public USE_GLOBAL_PEFI_VARIABLES;

    uint256 public POOL_CREATOR_FEE_BIPS_LOCAL;
    uint256 public NEST_FEE_BIPS_LOCAL;
    uint256 public DEV_FEE_BIPS_LOCAL;
    uint256 public ALTERNATE_FEE_BIPS_LOCAL;

    uint256 public constant MAX_TOTAL_FEE = 1000;
    uint256 internal constant BIPS_DIVISOR = 10000;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Reinvest(uint256 newTotalDeposits, uint256 newTotalSupply);
    event Recovered(address token, uint256 amount);
    event FeeStructureUpdated(
        uint256 newPOOL_CREATOR_FEE_BIPS,
        uint256 newNEST_FEE_BIPS,
        uint256 newDEV_FEE_BIPS,
        uint256 newALTERNATE_FEE_BIPS
    );
    event UpdateMinTokensToReinvest(uint256 oldValue, uint256 newValue);
    event UpdateMaxTokensToDepositWithoutReinvest(
        uint256 oldValue,
        uint256 newValue
    );
    event UpdateDevAddress(address oldValue, address newValue);
    event UpdateNestAddress(address oldValue, address newValue);
    event UpdatePoolCreatorAddress(address oldValue, address newValue);
    event UpdateAlternateAddress(address oldValue, address newValue);
    event DepositsEnabled(bool newValue);
    event UseGlobalVariablesUpdated(bool newValue);

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "PefiStrategy::onlyEOA");
        _;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender)
        external
        onlyOwner
    {
        require(IERC20(token).approve(spender, 0));
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint256 amount) external virtual;

    /**
     * @notice Deposit using Permit
     * @dev Should revert for tokens without Permit
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
    ) external virtual;

    /**
     * @notice Deposit on behalf of another account
     * @dev Must mint receipt tokens to `account`
     * @param account address to receive receipt tokens
     * @param amount deposit tokens
     */
    function depositFor(address account, uint256 amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint256 amount) external virtual;

    /**
     * @notice Reinvest reward tokens into deposit tokens
     */
    function reinvest() external virtual;

    /**
     * @notice Estimate reinvest reward
     * @return reward tokens
     */
    function estimateReinvestReward() external view returns (uint256) {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {
            return ((unclaimedRewards * POOL_CREATOR_FEE_BIPS()) /
                BIPS_DIVISOR);
        }
        return 0;
    }

    /**
     * @notice Reward tokens avialable to strategy, including balance
     * @return reward tokens
     */
    function checkReward() public view virtual returns (uint256);

    /**
     * @notice Rescue all available deployed deposit tokens back to Strategy
     * @param minReturnAmountAccepted min deposit tokens to receive
     * @param disableDeposits bool
     */
    function rescueDeployedFunds(
        uint256 minReturnAmountAccepted,
        bool disableDeposits
    ) external virtual;

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount)
        public
        view
        returns (uint256)
    {
        if ((totalSupply * totalDeposits) == 0) {
            return amount;
        }
        return ((amount * totalSupply) / totalDeposits);
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount)
        public
        view
        returns (uint256)
    {
        if ((totalSupply * totalDeposits) == 0) {
            return 0;
        }
        return ((amount * totalDeposits) / totalSupply);
    }

    function POOL_CREATOR_FEE_BIPS() public view returns (uint256) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.POOL_CREATOR_FEE_BIPS();
        } else {
            return POOL_CREATOR_FEE_BIPS_LOCAL;
        }
    }

    function NEST_FEE_BIPS() public view returns (uint256) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.NEST_FEE_BIPS();
        } else {
            return NEST_FEE_BIPS_LOCAL;
        }
    }

    function DEV_FEE_BIPS() public view returns (uint256) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.DEV_FEE_BIPS();
        } else {
            return DEV_FEE_BIPS_LOCAL;
        }
    }

    function ALTERNATE_FEE_BIPS() public view returns (uint256) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.ALTERNATE_FEE_BIPS();
        } else {
            return ALTERNATE_FEE_BIPS_LOCAL;
        }
    }

    function devAddress() public view returns (address) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.devAddress();
        } else {
            return devAddressLocal;
        }
    }

    function nestAddress() public view returns (address) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.nestAddress();
        } else {
            return nestAddressLocal;
        }
    }

    function alternateAddress() public view returns (address) {
        if (USE_GLOBAL_PEFI_VARIABLES) {
            return pefiGlobalVariableContract.alternateAddress();
        } else {
            return alternateAddressLocal;
        }
    }

    function updateUseGlobalVariables(bool newValue) external onlyOwner {
        USE_GLOBAL_PEFI_VARIABLES = newValue;
        emit UseGlobalVariablesUpdated(newValue);
    }

    /**
     * @notice Update reinvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToReinvest(uint256 newValue) public onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;
    }

    /**
     * @notice Update reinvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutReinvest(uint256 newValue)
        public
        onlyOwner
    {
        emit UpdateMaxTokensToDepositWithoutReinvest(
            MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST,
            newValue
        );
        MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST = newValue;
    }

    function updateFeeStructure(
        uint256 newPOOL_CREATOR_FEE_BIPS,
        uint256 newNEST_FEE_BIPS,
        uint256 newDEV_FEE_BIPS,
        uint256 newALTERNATE_FEE_BIPS
    ) public onlyOwner {
        require(
            (newPOOL_CREATOR_FEE_BIPS +
                newNEST_FEE_BIPS +
                newDEV_FEE_BIPS +
                newALTERNATE_FEE_BIPS) <= MAX_TOTAL_FEE,
            "new fees too high"
        );
        POOL_CREATOR_FEE_BIPS_LOCAL = newPOOL_CREATOR_FEE_BIPS;
        NEST_FEE_BIPS_LOCAL = newNEST_FEE_BIPS;
        DEV_FEE_BIPS_LOCAL = newDEV_FEE_BIPS;
        ALTERNATE_FEE_BIPS_LOCAL = newALTERNATE_FEE_BIPS;
        emit FeeStructureUpdated(
            newPOOL_CREATOR_FEE_BIPS,
            newNEST_FEE_BIPS,
            newDEV_FEE_BIPS,
            newALTERNATE_FEE_BIPS
        );
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(DEPOSITS_ENABLED != newValue);
        DEPOSITS_ENABLED = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update poolCreatorAddress
     * @param newValue address
     */
    function updatePoolCreatorAddress(address newValue) public onlyOwner {
        emit UpdatePoolCreatorAddress(poolCreatorAddress, newValue);
        poolCreatorAddress = newValue;
    }

    /**
     * @notice Update nestAddressLocal
     * @param newValue address
     */
    function updateNestAddress(address newValue) public onlyOwner {
        emit UpdateNestAddress(nestAddressLocal, newValue);
        nestAddressLocal = newValue;
    }

    /**
     * @notice Update devAddressLocal
     * @param newValue address
     */
    function updateDevAddress(address newValue) public onlyOwner {
        emit UpdateDevAddress(devAddressLocal, newValue);
        devAddressLocal = newValue;
    }

    /**
     * @notice Update alternateAddressLocal
     * @param newValue address
     */
    function updateAlternateAddress(address newValue) public onlyOwner {
        emit UpdateAlternateAddress(alternateAddressLocal, newValue);
        alternateAddressLocal = newValue;
    }

    /**
     * @notice Recover ERC20 tokens accidentally sent to contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        virtual
        onlyOwner
    {
        require(tokenAmount > 0, "cannot recover 0 tokens");
        require(
            tokenAddress != address(depositToken),
            "PefiStrategy:: cannot recover deposit token"
        );
        require(
            IERC20(tokenAddress).transfer(msg.sender, tokenAmount),
            "PefiStrategy:: token recovery failed"
        );
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param amount amount
     */
    function recoverAVAX(uint256 amount) external onlyOwner {
        require(amount > 0);
        payable(msg.sender).transfer(amount);
        emit Recovered(address(0), amount);
    }
}
