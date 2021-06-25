// https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./interfaces/controller.sol";

import "./lib/erc20.sol";
import "./lib/safe-math.sol";

contract PickleJar is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    address public governance;
    address public timelock;
    address public controller;

    address[] public underlyings;
    address public mainUnderlying;
    mapping (address => bool) public underlyingEnabled;
    mapping (address => address[]) public mainUnderlyingRoutes;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public routerAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    constructor(address _governance, address _timelock, address _controller, address _mainUnderlying)
        public
        ERC20("picklingUSD", "pUSD")
    {
        _setupDecimals(ERC20(_mainUnderlying).decimals());
        token = IERC20(_mainUnderlying);
        mainUnderlying = _mainUnderlying;
        governance = _governance;
        timelock = _timelock;
        controller = _controller;

        addUnderlying(usdc);
        addUnderlying(usdt);
        addUnderlying(dai);
        mainUnderlying = _mainUnderlying;
        mainUnderlyingRoutes[usdc] = [usdc, dai];
        mainUnderlyingRoutes[usdt] = [usdt, dai];
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

    function addUnderlying(address _underlying) public onlyGovernance {
        require(_underlying != address(0), "_underlying must be defined");
        underlyings.push(_underlying);
        underlyingEnabled[_underlying] = true;
    }

    function enableUnderlying(address _underlying) public onlyGovernance {
        require(_underlying != address(0), "_underlying must be defined");
        underlyingEnabled[_underlying] = true;
    }

    function disableUnderlying(address _underlying) public onlyGovernance {
        require(_underlying != address(0), "_underlying must be defined");
        underlyingEnabled[_underlying] = false;
    }

    function setMainUnderlyingRoute(address _underlying, address[] memory route) public onlyGovernance {
        require(_underlying != address(0), "_underlying must be defined");
        mainUnderlyingRoutes[_underlying] = route;
    }

    function setMainUnderlying(address _underlying) public onlyGovernance {
        require(_underlying != address(0), "_underlying must be defined");
        mainUnderlying = _underlying;
    }

    function setRouter(address _router) public onlyGovernance {
        require(_router != address(0), "_router must be defined");
        routerAddress = _router;
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

    function depositAll(_underlying) external {
        deposit(token.balanceOf(msg.sender), _underlying);
    }

    function deposit(uint256 _amount, address _underlying) public {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        IERC20(_underlying).safeTransferFrom(msg.sender, address(this), _amount);

        if (_underlying != mainUnderlying) {
            UniswapRouterV2(routerAddress).swapExactTokensForTokens(
                _amount,
                0,
                [_underlying, mainUnderlying],
                address(this),
                now.add(60)
            );
        }
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdrawAll(address _underlying) external {
        withdraw(balanceOf(msg.sender), _underlying);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares, address _underlying) public {
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

        if (_underlying != mainUnderlying) {
            UniswapRouterV2(routerAddress).swapExactTokensForTokens(
                r,
                0,
                [mainUnderlying, _underlying],
                address(this),
                now.add(60)
            );
        }

        token.safeTransfer(msg.sender, r);
    }

    function getRatio() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }
}
