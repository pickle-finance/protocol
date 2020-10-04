// CurveYCRVVoter: https://etherscan.io/address/0xF147b8125d2ef93FB6965Db97D6746952a133934#code

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/curve.sol";

contract CRVLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address
        public constant scrvGauge = 0xA90996896660DEcC6E997655E065b23788857849;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address public constant escrow = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;

    address public governance;
    address public voter;

    constructor(address _governance) public {
        governance = _governance;
    }

    function getName() external pure returns (string memory) {
        return "CRVLocker";
    }

    function setVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voter = _voter;
    }

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(scrvGauge, 0);
            IERC20(want).safeApprove(scrvGauge, _want);
            ICurveGauge(scrvGauge).deposit(_want);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == voter, "!voter");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(voter, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == voter, "!voter");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(want).safeTransfer(voter, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == voter, "!voter");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(voter, balance);
    }

    function _withdrawAll() internal {
        ICurveGauge(scrvGauge).withdraw(
            ICurveGauge(scrvGauge).balanceOf(address(this))
        );
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(msg.sender == voter || msg.sender == governance, "!authorized");
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        ICurveVotingEscrow(escrow).create_lock(_value, _unlockTime);
    }

    function increaseAmount(uint256 _value) external {
        require(msg.sender == voter || msg.sender == governance, "!authorized");
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        ICurveVotingEscrow(escrow).increase_amount(_value);
    }

    function increaseUnlockTime(uint256 _unlockTime) external {
        require(msg.sender == voter || msg.sender == governance, "!authorized");
        ICurveVotingEscrow(escrow).increase_unlock_time(_unlockTime);
    }

    function release() external {
        require(msg.sender == voter || msg.sender == governance, "!authorized");
        ICurveVotingEscrow(escrow).withdraw();
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        ICurveGauge(scrvGauge).withdraw(_amount);
        return _amount;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return ICurveGauge(scrvGauge).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
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
        require(msg.sender == voter || msg.sender == governance, "!governance");
        
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "!execute-success");

        return (success, result);
    }
}
