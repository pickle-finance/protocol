// https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./interfaces/controller.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

contract PickleJarCooldown is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    address public governance;
    address public timelock;
    address public controller;

    uint256 public cooldownTime = 7 days;
    uint256 public initialWithdrawalFee = 20;
    uint256 public initialWithdrawalFeeMax = 1000;

    mapping (address => uint256) public cooldownStartTime;

    constructor(address _token, address _governance, address _timelock, address _controller)
        public
        ERC20(
            string(abi.encodePacked("pickling ", ERC20(_token).name())),
            string(abi.encodePacked("p", ERC20(_token).symbol()))
        )
    {
        _setupDecimals(ERC20(_token).decimals());
        token = IERC20(_token);
        governance = _governance;
        timelock = _timelock;
        controller = _controller;
    }

    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(
                IController(controller).balanceOf(address(token))
            );
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        require(_min <= max, "numerator cannot be greater than denominator");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) public {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function setCooldownTime(uint256 _cooldownTime) external {
        require(msg.sender == governance, "!governance");
        cooldownTime = _cooldownTime;
    }

    function setInitialWithdrawalFee(uint256 fee, uint256 feeMax) external {
        require(msg.sender == governance, "!governance");
        require(fee <= feeMax, "Invalid fee");
        initialWithdrawalFee = fee;
        initialWithdrawalFeeMax = feeMax;
    }

    // Custom logic in here for how much the jars allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        cooldownStartTime[msg.sender] = now;
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) public {
        require(now >= cooldownStartTime[msg.sender], "!cooldown did not started");

        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        uint256 cooldownEndTime = cooldownStartTime[msg.sender] + cooldownTime;

        if (now < cooldownEndTime) {
            uint256 timeDiff = cooldownEndTime.sub(now);
            uint256 withdrawalFee = r.mul(initialWithdrawalFee).mul(timeDiff).div(cooldownTime).div(initialWithdrawalFeeMax);
            token.safeTransfer(IController(controller).devfund(), withdrawalFee);
            r = r.sub(withdrawalFee);
        }

        token.safeTransfer(msg.sender, r);
    }

    function getRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return balance().mul(1e18).div(totalSupply());
    }
}
