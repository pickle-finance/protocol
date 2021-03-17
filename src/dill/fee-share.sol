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

    uint256 public constant epoch_start = 1615579632;
    uint256 public constant epoch_period = 604800; // a week in seconds

    uint256[] public feesForEpoch;
    mapping(address => uint256) public claimedEpoches;

    event Claim(address indexed from, uint256 amount);

    function claim(address owner) external {
        _claimUntilEpoch(owner, currentEpoch().sub(1));
    }

    function claimUntilEpoch(address owner, uint256 until) external {
        _claimUntilEpoch(owner, until);
    }

    function _claimUntilEpoch(address owner, uint256 until) internal {
        require(until < currentEpoch(), "distribution not started!");

        uint256 amount = 0;
        uint256 _claimedEpoches = claimedEpoches[owner]; // check

        for (uint256 i = _claimedEpoches; i <= until; i ++) {
            uint256 epochTime = epoch_start.add(epoch_period.mul(i));

            amount += feesForEpoch[i].mul(dill.balanceOf(owner, epochTime)).div(dill.totalSupply(epochTime)); // fix
        }

        claimedEpoches[owner] = i;
        token.safeTransfer(owner, amount);

        emit Claim(owner, amount);
    }

    function distribute(uint256 amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), amount);
        feesForEpoch.push(amount);
    }

    function currentEpoch() public view returns(uint256) {
        return feesForEpoch.length;
    }
}
