// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

contract AnySwapBridger is Ownable {
    address public admin;

    mapping(uint256 => mapping(address => address)) receiveAddresses;

    constructor(address _admin) {
        admin = _admin;
    }

    function setReceiverAddress(
        uint256 _gaugeId,
        address _gauge,
        address _receiverAddress
    ) external onlyOwner {
        require(msg.sender == admin, "only called by admin");
        receiveAddresses[_gaugeId][_gauge] = _receiverAddress;
    }

    // function bridge(uint256 _gaugeId, address _gauge) external onlyOwner {
    //     require(msg.sender == admin, "only called by admin");
    //     require(_gaugeId > 0, "only called by admin");
    //     require(_gauge != address(0), "gauge cannot be zero");
    //     uint256 amount= AnyswapToken(_token).balanceOf(self)
    //     AnyswapToken(_token).Swapout(amount, self.root_receiver)
    // }
}
