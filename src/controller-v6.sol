// https://github.com/iearn-finance/jars/blob/master/contracts/controllers/StrategyControllerV1.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./lib/Initializable.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

import "./interfaces/jar.sol";
import "./interfaces/jar-converter.sol";
import "./interfaces/strategyv2.sol";
import "./interfaces/converter.sol";
import "./interfaces/univ3/IUniswapV3Pool.sol";

contract ControllerV6 is Initializable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public strategist;
    address public devfund;
    address public treasury;
    address public timelock;

    mapping(address => address) public jars;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => bool)) public approvedStrategies;

    function initialize(
        address _governance,
        address _strategist,
        address _timelock,
        address _devfund,
        address _treasury
    ) public initializer {
        governance = _governance;
        strategist = _strategist;
        timelock = _timelock;
        devfund = _devfund;
        treasury = _treasury;
    }

    function setDevFund(address _devfund) public {
        require(msg.sender == governance, "!governance");
        devfund = _devfund;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
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

    function setJar(address _pool, address _jar) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        jars[_pool] = _jar;
    }

    function approveStrategy(address _pool, address _strategy) public {
        require(msg.sender == timelock, "!timelock");
        approvedStrategies[_pool][_strategy] = true;
    }

    function revokeStrategy(address _pool, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(strategies[_pool] != _strategy, "cannot revoke active strategy");
        approvedStrategies[_pool][_strategy] = false;
    }

    function setStrategy(address _pool, address _strategy) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(approvedStrategies[_pool][_strategy] == true, "!approved");

        address _current = strategies[_pool];
        if (_current != address(0)) {
            IStrategyV2(_current).withdrawAll();
        }
        strategies[_pool] = _strategy;
    }

    function earn(
        address _pool,
        uint256 _token0Amount,
        uint256 _token1Amount
    ) public {
        address _strategy = strategies[_pool];
        address _want = IStrategyV2(_strategy).pool();
        require(_want == _pool, "pool address is different");

        IERC20(IUniswapV3Pool(_pool).token0()).safeTransfer(_strategy, _token0Amount);
        IERC20(IUniswapV3Pool(_pool).token1()).safeTransfer(_strategy, _token1Amount);
        IStrategyV2(_strategy).deposit();
    }

    function liquidityOf(address _pool) external view returns (uint256) {
        return IStrategyV2(strategies[_pool]).liquidityOf();
    }

    function withdrawAll(address _token) public returns (uint256 a0, uint256 a1) {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        (a0, a1) = IStrategyV2(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        IStrategyV2(_strategy).withdraw(_token);
    }

    function withdraw(address _pool, uint256 _amount) public returns (uint256 a0, uint256 a1) {
        require(msg.sender == jars[_pool], "!jar");
        (a0, a1) = IStrategyV2(strategies[_pool]).withdraw(_amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _execute(address _target, bytes memory _data) internal returns (bytes memory response) {
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }
}
