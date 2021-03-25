// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7; //^0.7.5;

import "../lib/erc20.sol";
import "../lib/ownable.sol";
import "../interfaces/dill.sol";

contract FeeShare is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    IERC20 public token = IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5); // PICKLE token
    IDill public dill = IDill(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf); // Dill, vePICKLE

    uint256 public constant epoch_period = 604800; // a week in seconds

    uint256 public startTime;
    uint256[] public feesForEpoch;
    mapping(address => uint256) public claimedEpoches;

    mapping(address => bool) public isDistributor;

    event Claim(address indexed from, uint256 amount, uint256 endingEpoch);

    function addDistributor(address account) public onlyOwner {
        isDistributor[account] = true;
    }

    function removeDistributor(address account) public onlyOwner {
        isDistributor[account] = false;
    }

    function setStartTime(uint256 timestamp) public onlyOwner {
        require(startTime == 0, "start time already set!");

        startTime = timestamp;
    }

    function distribute(uint256 amount) external {
        // require(msg.sender == owner() || isDistributor[msg.sender], "distributor not authorized!");
        token.safeTransferFrom(msg.sender, address(this), amount);
        feesForEpoch.push(amount);
    }

    function currentEpoch() public view returns(uint256) {
        return feesForEpoch.length;
    }

    function claim(address owner) external {
        _claimUntilEpoch(owner, currentEpoch().sub(1));
    }

    // endingEpoch starts from 0
    function claimUntilEpoch(address owner, uint256 endingEpoch) external {
        _claimUntilEpoch(owner, endingEpoch);
    }

    function getClaimable(address owner) external view returns(uint256) {
        return _getClaimableUntilEpoch(owner, currentEpoch().sub(1));
    }

    function getClaimableUntilEpoch(address owner, uint256 endingEpoch) external view returns(uint256) {
        return _getClaimableUntilEpoch(owner, endingEpoch);
    }

    function _getClaimableUntilEpoch(address owner, uint256 endingEpoch) internal view returns(uint256) {
        uint256 amount = 0;

        for (uint256 i = claimedEpoches[owner]; i <= endingEpoch; i ++) {
            uint256 epochStartTime = getEpochStartTime(i);
            uint256 totalSupply = dill.totalSupply(epochStartTime);

            if (totalSupply > 0) {
                amount += feesForEpoch[i].mul(dill.balanceOf(owner, epochStartTime)).div(totalSupply);
            }
        }

        return amount;
    }

    function _claimUntilEpoch(address owner, uint256 endingEpoch) internal {
        uint256 amount = _getClaimableUntilEpoch(owner, endingEpoch);
        token.safeTransfer(owner, amount);

        claimedEpoches[owner] = endingEpoch.add(1);

        emit Claim(owner, amount, endingEpoch);
    }

    function getEpochStartTime(uint256 epoch) internal view returns(uint256) {
        return startTime.add(epoch_period.mul(epoch));
    }
}
