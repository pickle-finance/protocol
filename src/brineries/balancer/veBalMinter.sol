// https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./../../lib/erc20.sol";
import "./../../lib/safe-math.sol";
import "../interfaces/brineries/balancer/IStrategyProxy.sol";

contract veBalMinter is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    address public governance;
    address public proxy;

    constructor(address _token, address _proxy)
        ERC20("pickling veBAL", "pveBAL")
    {
        token = IERC20(_token);
        governance = msg.sender;
        proxy = _proxy;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setProxy(address _proxy) public {
        require(msg.sender == governance, "!governance");
        proxy = _proxy;
    }

    function earn() public {
        uint256 _bal = token.balanceOf(address(this));
        token.safeApprove(proxy, 0);
        token.safeApprove(proxy, _bal);
        IStrategyProxy(proxy).lock(_bal);
    }

    function depositAll() external {
        _deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        _deposit(_amount);
    }

    function _deposit(uint256 _amount) internal {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }
}
