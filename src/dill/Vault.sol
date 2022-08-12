// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
import "./AnyCallApp.sol";
import "./Test/ITestERC20.sol";
import "./ISideChainGauge.sol";
import "./SideChainGauge.sol";
import "./ProtocolGovernance.sol";

contract Vault is AnyCallApp, ProtocolGovernance {
    ITestERC20 public PICKLE;

    mapping(address => address) public sideChainGauges;

    constructor(address pickle, address _governance)
        AnyCallApp(0xD7c295E399CA928A3a14b01D760E794f1AdF8990, 0)
    {
        PICKLE = ITestERC20(pickle);
        governance = _governance;
    }

    function addGauge(address mainchainGauge, address token) external {
        address gauge = sideChainGauges[mainchainGauge];
        require(gauge == address(0), "mainChainGauge is registered");
        gauge = address(new SideChainGauge(token, governance));
        sideChainGauges[mainchainGauge] = gauge;
    }

    function _anyExecute(bytes calldata data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (address to, uint256 amount) = abi.decode(data, (address, uint256));
        address gauge = sideChainGauges[to];
        require(gauge != address(0), "mainChainGauge is not registered");
        PICKLE.mintToken(gauge, amount);
        ISideChainGauge(gauge).notifyRewards();
        return (true, abi.encode(gauge, amount));
    }
}
