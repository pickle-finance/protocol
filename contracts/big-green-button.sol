pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "controller-v4.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

contract ControllerV4 {
    function setGlobe(address _token, address _globe) public {}
    function approveStrategy(address _token, address _strategy) public {}
    function revokeStrategy(address _token, address _strategy) public {}
    function setStrategy(address _token, address _strategy) public {}
}

contract BigGreenButton {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    ControllerV4 controller;

    constructor(
        address _controller
    ) public {
        controller = ControllerV4(_controller);
    }

    function setGlobes(address[] _tokens, address[] _globes) public {
        require(
            msg.sender == controller.strategist() || msg.sender == controller.governance(),
            "!strategist"
        );
        require(_tokens.length == _globes.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            controller.setGlobe(_tokens[i], _globes[i]);
        }
    }

    function approveStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == controller.timelock(), "!timelock");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            controller.approveStrategy(_tokens[i], _strategies[i]);
        }
    }

    function revokeStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == controller.governance(), "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            controller.revokeStrategy(_tokens[i], _strategies[i]);
        }
    }

    function setStrategies(address[] _tokens, address[] _strategies) public {
        require(
            msg.sender == controller.strategist() || msg.sender == controller.governance(),
            "!strategist"
        );
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            controller.setStrategy(_tokens[i], _strategies[i]);
        }
    }
}
