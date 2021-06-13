pragma solidity ^0.6.7;

import "../lib/yearn-affiliate-wrapper.sol";
import "../interfaces/controller.sol";
import {ERC20} from "../lib/erc20.sol";

contract StrategyYearnAffiliate is YearnAffiliateWrapper {

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    address public want;

    string public name;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    // **** Getters ****
    constructor(
        address _want,
        address _yearnRegistry,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public YearnAffiliateWrapper(_want, _yearnRegistry) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;

        name = string(abi.encodePacked("y", ERC20(_want).symbol(), " Affiliate Strategy"));
    }

    function balanceOfWant() public view returns (uint256) {
        return 0; // IERC20(want).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return totalVaultBalance(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return balanceOf();
    }

    function getName() external returns (string memory) {
        return name;
    }

    // **** Setters ****

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function deposit() public {
        require(msg.sender == controller, "!controller");
        uint256 _want = IERC20(want).balanceOf(address(this));
        _deposit(address(this), address(this), _want, false);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");

        _withdrawSome(_amount);

        uint256 _balance = IERC20(want).balanceOf(address(this));

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_jar, _balance);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar");
        IERC20(want).safeTransfer(_jar, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawSome(balanceOf());

        balance = IERC20(want).balanceOf(address(this));

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_jar, balance);
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        return _withdraw(address(this), address(this), _amount, true); // `true` = withdraw from `bestVault`
    }

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }

    function migrate() external onlyGovernance returns (uint256) {
        return _migrate(address(this));
    }

    function migrate(uint256 amount) external onlyGovernance returns (uint256) {
        return _migrate(address(this), amount);
    }

    function migrate(uint256 amount, uint256 maxMigrationLoss) external onlyGovernance returns (uint256) {
        return _migrate(address(this), amount, maxMigrationLoss);
    }
}
