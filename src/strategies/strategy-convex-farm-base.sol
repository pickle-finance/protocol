pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/curve.sol";
import "../interfaces/convex-farm.sol";

abstract contract StrategyConvexFarmBase is StrategyBase {
    address public convexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    uint256 public poolId;

    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

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

    function getCrvRewardContract() public view returns (address) {
        (, , , address crvRewards, , ) = IConvexBooster(convexBooster).poolInfo(
            poolId
        );
        return crvRewards;
    }

    function balanceOfPool() public view override returns (uint256) {
        return IBaseRewardPool(getCrvRewardContract()).balanceOf(address(this));
    }

    function get_crv_earned() public view returns (uint256) {
        return IBaseRewardPool(getCrvRewardContract()).earned(address(this));
    }

    function get_cvx_earned() public view virtual returns (uint256) {
        uint256 crv_earned = get_crv_earned();

        uint256 supply = IConvexToken(cvx).totalSupply();
        if (supply == 0) {
            return crv_earned;
        }
        uint256 reductionPerCliff = IConvexToken(cvx).reductionPerCliff();
        uint256 totalCliffs = IConvexToken(cvx).totalCliffs();
        uint256 cliff = supply.div(reductionPerCliff);

        uint256 maxSupply = IConvexToken(cvx).maxSupply();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs.sub(cliff);
            uint256 _amount = crv_earned;

            _amount = _amount.mul(reduction).div(totalCliffs);
            //supply cap check
            uint256 amtTillMax = maxSupply.sub(supply);
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
            return _amount;
        }
        return 0;
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(convexBooster, 0);
            IERC20(want).safeApprove(convexBooster, _want);

            IConvexBooster(convexBooster).deposit(poolId, _want, true);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBaseRewardPool(getCrvRewardContract()).withdrawAndUnwrap(
            _amount,
            false
        );
        return _amount;
    }
}
