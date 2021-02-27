pragma solidity 0.6.7;

import "../lib/erc20.sol";
import "../lib/ownable.sol";

// SnowballToken with Governance.
contract SnowToken is ERC20("SnowToken", "SNOW"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (IceQueen).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
