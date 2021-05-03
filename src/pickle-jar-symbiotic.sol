// https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol

pragma solidity ^0.6.7;

import "./interfaces/controller.sol";

import "./lib/erc20.sol";
import "./interfaces/strategy.sol";
import "./lib/safe-math.sol";

contract PickleJarSymbiotic is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;
    IERC20 public reward;

    mapping(address => uint256) public userRewardDebt;

    uint256 private accRewardPerShare;
    uint256 private lastPendingReward;
    uint256 private curPendingReward;

    uint256 public min = 10000;
    uint256 public constant max = 10000;

    address public governance;
    address public timelock;
    address public controller;

    event Deposit(address indexed user, uint256 _amount, uint256 _shares);
    event Withdraw(address indexed user, uint256 _amount, uint256 _shares);

    constructor(
        address _token,
        address _reward,
        address _governance,
        address _timelock,
        address _controller
    )
        public
        ERC20(
            string(abi.encodePacked("pickling ", ERC20(_token).name())),
            string(abi.encodePacked("p", ERC20(_token).symbol()))
        )
    {
        _setupDecimals(ERC20(_token).decimals());
        token = IERC20(_token);
        reward = IERC20(_reward);
        governance = _governance;
        timelock = _timelock;
        controller = _controller;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
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
        require(_amount > 0, "Invalid amount");
        _updateAccPerShare();
        
        _withdrawReward();

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
        _mint(msg.sender, shares);
        userRewardDebt[msg.sender] = balanceOf(msg.sender).mul(accRewardPerShare).div(1e36);
        emit Deposit(msg.sender, _amount, shares);
        earn(); //earn everytime deposit happens
    }

    function _updateAccPerShare() internal {
        if (totalSupply() == 0) return;
        curPendingReward = pendingReward();
        uint256 addedReward = curPendingReward.sub(lastPendingReward);
        accRewardPerShare = accRewardPerShare.add((addedReward.mul(1e36)).div(totalSupply()));
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

    function pendingReward() public view returns (uint256) {
        return reward.balanceOf(address(this)).add(IStrategy(IController(controller).strategies(address(token))).pendingReward());
    }

    function _withdrawReward() internal {
        uint256 _pending = balanceOf(msg.sender).mul(accRewardPerShare).div(1e36).sub(userRewardDebt[msg.sender]);
        uint256 _balance = reward.balanceOf(address(this));
        if (_balance < _pending) {
            uint256 _withdraw = _pending.sub(_balance);
            IController(controller).withdrawReward(address(token), _withdraw);
            uint256 _after = reward.balanceOf(address(this));
            uint256 _diff = _after.sub(_balance);
            if (_diff < _withdraw) {
                _pending = _balance.add(_diff);
            }
        }
        reward.safeTransfer(msg.sender, _pending);
        lastPendingReward = curPendingReward.sub(_pending);
    }

    function withdraw(uint256 _shares) public {
        require(balanceOf(msg.sender) >= _shares, "Invalid amount");
        _updateAccPerShare();
        _withdrawReward();

        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);
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
        token.safeTransfer(msg.sender, r);

        userRewardDebt[msg.sender] = balanceOf(msg.sender).mul(accRewardPerShare).div(1e36);

        emit Withdraw(msg.sender, r, _shares);
    }

    function getRatio() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }
}
