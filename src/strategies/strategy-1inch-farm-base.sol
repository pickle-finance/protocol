// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/1inch-farm-lp.sol";
import "../interfaces/1inch-farm.sol";

abstract contract Strategy1inchFarmBase is StrategyBase {
    // Token addresses
    // oneinch is not using WETH, tokenA address for 1inch ETH/token1 pool is 0x0000000000000000000000000000000000000000
    // oneinch has farmingrewards pool per one 1inch-lp token

    address public constant oneinch = 0x111111111117dC0aa78b770fA6A738034120C302;

    //use this pool to swap 1inch to ETH (not weth), 1inch doens't use WETH
    address public constant oneinch_eth_pool = 0x0EF1B8a0E726Fc3948E15b23993015eB1627f210;

    //address public constant oneinchFactory = 0xbaf9a5d4b0052359326a6cdab54babaa3a3a9643;
    address public oneinchFarmPool;

    // ETH/<token1> pair
    address public token1;

    // How much 1inch tokens to keep?
    uint256 public keep1inch = 0;
    uint256 public constant keep1inchMax = 10000;


    constructor(
        address _token1,
        address _lp,
        address _pool,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        oneinchFarmPool = _pool;
        token1 = _token1;
    }
    
    function balanceOfPool() public override view returns (uint256) {
        uint256 amount = IOneInchFarm(oneinchFarmPool).balanceOf(address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IOneInchFarm(oneinchFarmPool).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this)); //want means 1inch lp token
        if (_want > 0) {
            IERC20(want).safeApprove(oneinchFarmPool, 0);
            IERC20(want).safeApprove(oneinchFarmPool, _want);
            IOneInchFarm(oneinchFarmPool).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IOneInchFarm(oneinchFarmPool).withdraw(_amount);
        return _amount;
    }

    // **** Setters ****

    function setKeep1inch(uint256 _keep1inch) external {
        require(msg.sender == timelock, "!timelock");
        keep1inch = _keep1inch;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects 1inch tokens
        IOneInchFarm(oneinchFarmPool).getReward();
        uint256 _oneinch = IERC20(oneinch).balanceOf(address(this));
        if (_oneinch > 0) {
            // 10% is locked up for future gov
            uint256 _keep1inch = _oneinch.mul(keep1inch).div(keep1inchMax);
            IERC20(oneinch).safeTransfer(
                IController(controller).treasury(),
                _keep1inch
            );
            _oneinchSwap(oneinch, address(0), _oneinch.sub(_keep1inch), oneinch_eth_pool);
            //claim Opium functions here
        }

        // Swap half ETH for Token1 (e.g. Opium)
        uint256 _eth = address(this).balance;
        if (_eth > 0) {
            _oneinchSwap(address(0), token1, _eth.div(2), want);
        }

        _eth = address(this).balance;
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_eth > 0 && _token1 > 0) {
            //no need to approve ETH, it's not WETH

            IERC20(token1).safeApprove(want, 0);
            IERC20(token1).safeApprove(want, _token1);

            uint256[2] memory maxAmounts;
            uint256[2] memory minAmounts;
            maxAmounts[0] = _eth;
            maxAmounts[1] = _token1;
            minAmounts[0] = 0;
            minAmounts[1] = 0;

            IMooniswap(want).deposit(maxAmounts, minAmounts);

            // Donates DUST
            address payable _treasury = payable(IController(controller).treasury());
            _treasury.transfer(address(this).balance); //send ETH to treasury

            IERC20(token1).safeTransfer(
                _treasury,
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back 1inch LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
