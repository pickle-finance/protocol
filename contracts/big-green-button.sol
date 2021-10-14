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

    address public governance;
    address public strategist;
    address public timelock;

    constructor(
        address _controller
        address _governance,
        address _strategist,
        address _timelock,
    ) public {
        governance = _governance;
        strategist = _strategist;
        timelock = _timelock;
        controller = _controller;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setGlobes(address[] _tokens, address[] _globes) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(_tokens.length == _globes.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).setGlobe(_tokens[i], _globes[i]);
        }
    }

    function approveStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == timelock, "!timelock");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).approveStrategy(_tokens[i], _strategies[i]);
        }
    }

    function revokeStrategies(address[] _tokens, address[] _strategies) public {
        require(msg.sender == governance, "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).revokeStrategy(_tokens[i], _strategies[i]);
        }
    }

    function setStrategies(address[] _tokens, address[] _strategies) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(controller).setStrategy(_tokens[i], _strategies[i]);
        }
    }
}
