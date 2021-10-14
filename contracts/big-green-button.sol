pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./interfaces/controller.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

contract BigGreenButton {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;

    constructor(
        address _governance,
    ) public {
        governance = _governance;
    }

    function setStrategist(address _controller, address _strategist) public {
        require(msg.sender == governance, "!governance");
        IController(_controller).setStrategist(_strategist);
    }

    function setGovernance(address _controller, address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
        IController(_controller).setGovernance(_governance);
    }

    function setTimelock(address _controller, address _timelock) public {
        require(msg.sender == governance, "!governance");
        IController(_controller).setTimelock(_timelock);
    }

    function setGlobes(address _controller, address[] _tokens, address[] _globes) public {
        require(msg.sender == governance, "!governance");
        require(_tokens.length == _globes.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(_controller).setGlobe(_tokens[i], _globes[i]);
        }
    }

    function approveStrategies(address _controller, address[] _tokens, address[] _strategies) public {
        require(msg.sender == governance, "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(_controller).approveStrategy(_tokens[i], _strategies[i]);
        }
    }

    function revokeStrategies(address _controller, address[] _tokens, address[] _strategies) public {
        require(msg.sender == governance, "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(_controller).revokeStrategy(_tokens[i], _strategies[i]);
        }
    }

    function setStrategies(address _controller, address[] _tokens, address[] _strategies) public {
        require(msg.sender == governance, "!governance");
        require(_tokens.length == _strategies.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IController(_controller).setStrategy(_tokens[i], _strategies[i]);
        }
    }
}
