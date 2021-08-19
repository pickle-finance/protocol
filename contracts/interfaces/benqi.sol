// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IQiToken {
    function totalSupply() external view returns (uint256);

    function totalBorrows() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
}

interface IQiAvax {
    function mint() external payable;

    /**
     * @notice Sender redeems qiTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of qiTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems qiTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    function repayBorrow() external payable;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being payed off
     */
    function repayBorrowBehalf(address borrower) external payable;

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this qiToken to be liquidated
     * @param qiTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrow(address borrower, address qiTokenCollateral)
        external
        payable;
}

interface IComptroller {
    function compAccrued(address) external view returns (uint256);

    function compSupplierIndex(address, address)
        external
        view
        returns (uint256);

    function compBorrowerIndex(address, address)
        external
        view
        returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function compBorrowState(address) external view returns (uint224, uint32);

    function compSupplyState(address) external view returns (uint224, uint32);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata qiTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address qiToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address qiToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address qiToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address qiToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address qiToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address qiToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address qiToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    // Claim all the Qi accrued by holder in all markets
    function claimQi(address holder) external;

    // Claim all the Qi accrued by holder in specific markets
    function claimQi(address holder, address[] calldata qiTokens) external;

    // Claim all the Qi accrued by specific holders in specific markets for their supplies and/or borrows
    function claimQi(
        address[] calldata holders,
        address[] calldata qiTokens,
        bool borrowers,
        bool suppliers
    ) external;

    function markets(address qiTokenAddress)
        external
        view
        returns (bool, uint256);
}

interface IBenqiLens {
    function getQiBalanceMetadataExt(
        address qi,
        address comptroller,
        address account
    )
        external
        returns (
            uint256 balance,
            uint256 votes,
            address delegate,
            uint256 allocated
        );
}
