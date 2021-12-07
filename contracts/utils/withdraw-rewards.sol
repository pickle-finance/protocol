pragma solidity ^0.6.7;

import "../lib/erc20.sol";


// Old Strategy should call executeFunction(withdraw([tokens...], target));
contract WithdrawRewards {
  using SafeERC20 for IERC20;

  function withdraw(address[] calldata _tokens, address _target) external {
    address _token;

    for (uint i = 0; i < _tokens.length; i++) {
      _token = _tokens[i];
      IERC20(_token).safeTransfer(_target, IERC20(_token).balanceOf(address(this)));
    }
  }

}