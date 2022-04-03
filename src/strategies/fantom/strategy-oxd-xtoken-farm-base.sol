// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/oxd-chef.sol";

abstract contract StrategyOxdXtokenFarmBase is StrategyBase {
    // Token addresses
    address public constant oxd = 0xc165d941481e68696f43EE6E99BFB2B23E0E3114;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    address public constant oxdChef =
        0xa7821C3e9fC1bF961e280510c471031120716c3d;
    address public underlying;
    string public functionSignature;

    address public token0;
    address public token1;

    // How much OXD tokens to keep?
    uint256 public keepOXD = 420;
    uint256 public constant keepOXDMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;

    constructor(
        address _xtoken,
        address _underlying,
        uint256 _poolId,
        string memory _funcSig,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_xtoken, _governance, _strategist, _controller, _timelock)
    {
        // Spooky router
        sushiRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        underlying = _underlying;
        functionSignature = _funcSig;
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IOxdChef(oxdChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IOxdChef(oxdChef).pendingOXD(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(oxdChef, 0);
            IERC20(want).safeApprove(oxdChef, _want);
            IOxdChef(oxdChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IOxdChef(oxdChef).withdraw(poolId, _amount);
        return _amount;
    }

    function setKeepOXD(uint256 _keepOXD) external {
        require(msg.sender == timelock, "!timelock");
        keepOXD = _keepOXD;
    }

    // **** State Mutations ****

    function harvest() public virtual override {
        // Collects OXD tokens
        IOxdChef(oxdChef).deposit(poolId, 0);
        uint256 _oxd = IERC20(oxd).balanceOf(address(this));

        if (_oxd > 0) {
            uint256 _keepOXD = _oxd.mul(keepOXD).div(keepOXDMax);
            IERC20(oxd).safeTransfer(
                IController(controller).treasury(),
                _keepOXD
            );
            _oxd = _oxd.sub(_keepOXD);

            if (swapRoutes[underlying].length > 1) {
                _swapSushiswapWithPath(swapRoutes[underlying], _oxd);
            }
        }

        // Stakes in Xtoken contract
        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeApprove(want, 0);
        IERC20(underlying).safeApprove(want, _underlying);

        (bool success, ) = want.call(
            abi.encodeWithSignature(functionSignature, _underlying)
        );

        require(success, "deposit failed");
        _distributePerformanceFeesAndDeposit();
    }
}
