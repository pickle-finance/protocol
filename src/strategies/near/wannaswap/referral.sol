pragma solidity ^0.6.7;

import "../../../interfaces/minichef-wanna.sol";

contract Referral {
    function setReferral(uint256 poolId) external {
        address minichef = 0x2B2e72C232685fC4D350Eaa92f39f6f8AD2e1593;

        IMiniChefWanna(miniChef).deposit(poolId, 0, address(this));
    }
}
