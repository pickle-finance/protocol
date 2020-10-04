// https://etherscan.io/address/0xF147b8125d2ef93FB6965Db97D6746952a133934

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/staking-rewards.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

contract StrategyUniEthDaiLpV3 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Staking rewards address for ETH/DAI LP providers
    address
        public constant rewards = 0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711;

    // want eth/dai lp tokens
    address public constant want = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    // tokens we're farming
    address public constant uni = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // pickle token
    address public constant pickle = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;

    // weth
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // burn address
    address public constant burn = 0x000000000000000000000000000000000000dEaD;

    // dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // How much UNI tokens to keep?
    uint256 public keepUNI = 0;
    uint256 public constant keepUNIMax = 10000;

    // Perfomance fee 4.5%
    uint256 public performanceFee = 450;
    uint256 public constant performanceMax = 10000;

    // Withdrawal fee 0.5%
    // - 0.375% to treasury
    // - 0.125% to dev fund
    uint256 public treasuryFee = 375;
    uint256 public constant treasuryMax = 100000;

    uint256 public devFundFee = 125;
    uint256 public constant devFundMax = 100000;

    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    // **** Views ****

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure returns (string memory) {
        return "StrategyUniEthDaiLpV3";
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function setKeepUNI(uint256 _keepUNI) external {
        require(msg.sender == governance, "!governance");
        keepUNI = _keepUNI;
    }

    function setDevFundFee(uint256 _devFundFee) external {
        require(msg.sender == governance, "!governance");
        devFundFee = _devFundFee;
    }

    function setTreasuryFee(uint256 _treasuryFee) external {
        require(msg.sender == governance, "!governance");
        treasuryFee = _treasuryFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    // **** State Mutations ****

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).approve(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
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
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(devFundFee).div(devFundMax);
        IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);

        uint256 _feeTreasury = _amount.mul(treasuryFee).div(treasuryMax);
        IERC20(want).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_jar, _amount.sub(_feeDev).sub(_feeTreasury));
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_jar, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }

    function brine() public {
        harvest();
    }

    function harvest() public {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects UNI tokens
        IStakingRewards(rewards).getReward();
        uint256 _uni = IERC20(uni).balanceOf(address(this));
        if (_uni > 0) {
            // 10% is locked up for future gov
            uint256 _keepUNI = _uni.mul(keepUNI).div(keepUNIMax);
            IERC20(uni).safeTransfer(
                IController(controller).treasury(),
                _keepUNI
            );
            _swap(uni, weth, _uni.sub(_keepUNI));
        }

        // Swap half WETH for DAI
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swap(weth, dai, _weth.div(2));
        }

        // Adds in liquidity for ETH/DAI
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_weth > 0 && _dai > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);

            IERC20(dai).safeApprove(univ2Router2, 0);
            IERC20(dai).safeApprove(univ2Router2, _dai);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                dai,
                _weth,
                _dai,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(dai).transfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
            );
        }

        // We want to get back UNI ETH/DAI LP tokens
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            // Performance fee
            IERC20(want).safeTransfer(
                IController(controller).treasury(),
                _want.mul(performanceFee).div(performanceMax)
            );

            deposit();
        }
    }

    // Emergency proxy pattern
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

    // **** Internal functions ****
    function _swap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Swap with uniswap
        IERC20(_from).safeApprove(univ2Router2, 0);
        IERC20(_from).safeApprove(univ2Router2, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}
