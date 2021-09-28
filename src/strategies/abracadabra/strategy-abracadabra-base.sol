pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/sorbettiere-farm.sol";

abstract contract StrategyAbracadabraFarmBase is StrategyBase {
    address public sorbettiere = 0xF43480afE9863da4AcBD4419A47D9Cc7d25A647F;
    uint256 public poolId;
    address public constant ice = 0x090185f2135308BaD17527004364eBcC2D37e5F6;

    uint256 public keepIce = 0;
    uint256 public constant keepIceMax = 10000;

    constructor(
        address _lp,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
    }

    function setKeepSUSHI(uint256 _keepIce) external {
        require(msg.sender == timelock, "!timelock");
        keepIce = _keepIce;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , ) = ISorbettiereFarm(sorbettiere).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return ISorbettiereFarm(sorbettiere).pendingIce(poolId, address(this));
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sorbettiere, 0);
            IERC20(want).safeApprove(sorbettiere, _want);

            ISorbettiereFarm(sorbettiere).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISorbettiereFarm(sorbettiere).withdraw(poolId, _amount);
        return _amount;
    }
}