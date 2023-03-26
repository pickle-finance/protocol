// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../lib/erc20.sol";
import "../interfaces/controller.sol";

// Strategy Contract Basics

abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Perfomance fees
    uint256 public performanceTreasuryFee = 0;
    uint256 public constant performanceTreasuryMax = 10000;

    // Withdrawal fee
    uint256 public withdrawalTreasuryFee = 0;
    uint256 public constant withdrawalTreasuryMax = 100000;

    // Tokens
    address public immutable want;
    address public immutable native;
    address[] public activeRewardsTokens;

    // Permissioned accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;
    address public pendingTimelock;
    mapping(address => bool) public harvesters;

    constructor(
        address _want,
        address _native,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) {
        // Sanity checks
        require(_want != address(0));
        require(_native != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        // Constants assignments
        want = _want;
        native = _native;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyHarvester() {
        require(
            harvesters[msg.sender] || msg.sender == strategist || msg.sender == governance || msg.sender == timelock,
            "!harvester"
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist || msg.sender == governance || msg.sender == timelock, "!strategist");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance || msg.sender == timelock, "!governance");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "!timelock");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "!controller");
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256) {}

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure virtual returns (string memory);

    function getHarvestable() external view virtual returns (address[] memory, uint256[] memory);

    function getActiveRewardsTokens() external view returns (address[] memory) {
        return activeRewardsTokens;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external onlyHarvester {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external onlyStrategist {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setWithdrawalTreasuryFee(uint256 _withdrawalTreasuryFee) external onlyTimelock {
        withdrawalTreasuryFee = _withdrawalTreasuryFee;
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee) external onlyTimelock {
        performanceTreasuryFee = _performanceTreasuryFee;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setPendingTimelock(address _pendingTimelock) external onlyTimelock {
        pendingTimelock = _pendingTimelock;
    }

    function acceptTimelock() external {
        require(msg.sender == pendingTimelock, "!pendingTimelock");
        timelock = pendingTimelock;
        pendingTimelock = address(0);
    }

    function setController(address _controller) external onlyTimelock {
        controller = _controller;
    }

    // **** State mutations **** //

    // Adds/updates a swap path from a token to native, normally used for adding/updating a reward path
    function addToNativeRoute(bytes calldata _route) external onlyStrategist {
        _addToNativeRoute(_route);
    }

    function addToTokenRoute(bytes calldata _route) external onlyStrategist {
        _addToTokenRoute(_route);
    }

    function _addToTokenRoute(bytes memory _route) internal virtual;

    function _addToNativeRoute(bytes memory _route) internal virtual;

    function deactivateReward(address _reward) external onlyStrategist {
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            if (activeRewardsTokens[i] == _reward) {
                activeRewardsTokens[i] = activeRewardsTokens[activeRewardsTokens.length - 1];
                activeRewardsTokens.pop();
            }
        }
    }

    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external onlyController returns (uint256 balance) {
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external onlyController {
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_jar, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external onlyController returns (uint256 balance) {
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_jar, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data) public payable onlyTimelock returns (bytes memory response) {
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

    function _distributePerformanceFeesNative() internal {
        uint256 _native = IERC20(native).balanceOf(address(this));
        if (_native > 0) {
            // Treasury fees
            IERC20(native).safeTransfer(
                IController(controller).treasury(),
                _native.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );
        }
    }
}
