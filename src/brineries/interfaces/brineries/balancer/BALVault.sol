// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
interface IBALVault {
    
        struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
}
