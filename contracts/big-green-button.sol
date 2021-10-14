pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./interfaces/controller.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

contract BigGreenButton {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address controller;

    constructor(
        address _controller
    ) public {
        controller = _controller;
    }

    function setGlobes(address[] _tokens, address[] _globes) public {
        require(
            msg.sender == IController(controller).strategist() || msg.sender == IController(controller).governance(),
            "!strategist"
        );
        require(_tokens.length == _globes.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).setGlobe(_tokens[i], _globes[i]);
        }
    }

    function approveStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == IController(controller).timelock(), "!timelock");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).approveStrategy(_tokens[i], _strategies[i]);
        }
    }

    function revokeStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == IController(controller).governance(), "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).revokeStrategy(_tokens[i], _strategies[i]);
        }
    }

    function setStrategies(address[] _tokens, address[] _strategies) public {
        require(
            msg.sender == IController(controller).strategist() || msg.sender == IController(controller).governance(),
            "!strategist"
        );
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).setStrategy(_tokens[i], _strategies[i]);
        }
    }
}
