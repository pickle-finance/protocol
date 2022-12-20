// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11; //^0.6.7

import "../../lib/erc20.sol";
import "../interfaces/brineries/balancer/VoteEscrow.sol";

contract BALLocker {
    using SafeERC20 for IERC20;
    using Address for address;

    address public constant bal =
        address(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);

    address public constant escrow =
        address(0xC128a9954e6c874eA3d62ce62B468bA073093F25);

    address public governance;
    address public strategy;

    constructor() {
        governance = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "BALLocker";
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        IERC20(bal).safeApprove(escrow, 0);
        IERC20(bal).safeApprove(escrow, _value);
        VoteEscrow(escrow).create_lock(_value, _unlockTime);
    }

    function increaseAmount(uint256 _value) external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        IERC20(bal).safeApprove(escrow, 0);
        IERC20(bal).safeApprove(escrow, _value);
        VoteEscrow(escrow).increase_amount(_value);
    }

    function increaseUnlockTime(uint256 _unlockTime) external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        VoteEscrow(escrow).increase_unlock_time(_unlockTime);
    }

    function release() external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
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
        require(
            msg.sender == strategy || msg.sender == governance,
            "!governance"
        );
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
