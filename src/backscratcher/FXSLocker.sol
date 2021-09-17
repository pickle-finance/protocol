// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";
import "../interfaces/backscratcher/VoteEscrow.sol";

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract FXSLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    address public constant escrow = address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);

    address public governance;
    address public strategy;

    constructor() public {
        governance = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "FXSLocker";
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(fxs).safeApprove(escrow, 0);
        IERC20(fxs).safeApprove(escrow, _value);
        VoteEscrow(escrow).create_lock(_value, _unlockTime);
    }

    function increaseAmount(uint256 _value) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(fxs).safeApprove(escrow, 0);
        IERC20(fxs).safeApprove(escrow, _value);
        VoteEscrow(escrow).increase_amount(_value);
    }

    function release() external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        VoteEscrow(escrow).withdraw();
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory) {
        require(msg.sender == strategy || msg.sender == governance, "!governance");
        (bool success, bytes memory result) = to.call{value: value}(data);

        return (success, result);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
