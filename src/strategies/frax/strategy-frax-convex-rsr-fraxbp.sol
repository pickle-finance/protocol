pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../interfaces/saddle-farm.sol";
import "../../interfaces/curve.sol";

interface IVaultFactory {
    function createVault(uint256 _pid) external returns (address);
}

interface IConvexPersonalVault {
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    function getReward() external;

    function withdrawLockedAndUnwrap(bytes32) external;
}

contract StrategyFraxConvexRsrFraxBP is StrategyBase {
    uint256 private PID = 37;
    address private VAULT_FACTORY = 0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa;

    address private RSR_FRAXBP_TOKEN = 0x3F436954afb722F5D14D868762a23faB6b0DAbF0;
    address private RSR_FRAXBP_POOL = 0x6a6283aB6e31C2AeC3fA08697A8F806b740660b2;
    address private CURVE_ZAP = 0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895;

    address private FRAX_FARM = 0xF22D3C85e41Ef4b5Ac8Cb8B89a14718e290a0561;

    address private crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address private frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    uint24 private constant poolFee = 10000;

    // Uniswap swap paths
    address[] private fxs_frax_path;

    address immutable convexPersonalVault;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(RSR_FRAXBP_TOKEN, _governance, _strategist, _controller, _timelock) {
        convexPersonalVault = IVaultFactory(VAULT_FACTORY).createVault(PID);

        fxs_frax_path = new address[](2);
        fxs_frax_path[0] = fxs;
        fxs_frax_path[1] = frax;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyFraxConvexRsrFraxBP";
    }

    function balanceOfPool() public view override returns (uint256) {
        return ICommunalFarm(FRAX_FARM).lockedLiquidityOf(convexPersonalVault);
    }

    function getHarvestable() public view returns (uint256[] memory) {
        return ICommunalFarm(FRAX_FARM).earned(address(this));
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 _min = ICommunalFarm(FRAX_FARM).lock_time_min();
            IERC20(want).safeApprove(convexPersonalVault, 0);
            IERC20(want).safeApprove(convexPersonalVault, _want);
            IConvexPersonalVault(convexPersonalVault).stakeLockedCurveLp(_want, _min);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        LockedStake[] memory lockedStakes = ICommunalFarm(FRAX_FARM).lockedStakesOf(convexPersonalVault);
        uint256 _sum = 0;
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < lockedStakes.length; i++) {
            if (lockedStakes[i].liquidity == 0) continue;

            _sum = _sum.add(lockedStakes[i].liquidity);
            count++;
            if (_sum >= _amount) break;
        }
        require(_sum >= _amount, "insufficient amount");

        for (i = 0; i < count; i++) {
            if (lockedStakes[i].liquidity > 0)
                IConvexPersonalVault(convexPersonalVault).withdrawLockedAndUnwrap(lockedStakes[i].kek_id);
        }
        uint256 _balance = IERC20(want).balanceOf(address(this));

        require(_balance >= _amount, "withdraw failed");

        return _amount;
    }

    function harvest() public override onlyBenevolent {
        deposit();
        IConvexPersonalVault(convexPersonalVault).getReward();

        // Step 1: Swap CRV -> ETH -> FXS
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(univ3Router, 0);
            IERC20(crv).safeApprove(univ3Router, _crv);
            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(crv, poolFee, weth, poolFee, fxs),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _crv,
                    amountOutMinimum: 0
                })
            );
        }

        // Step 2: Swap CVX -> ETH -> FXS
        uint256 _cvx = IERC20(cvx).balanceOf(address(this));

        if (_cvx > 0) {
            IERC20(cvx).safeApprove(univ3Router, 0);
            IERC20(cvx).safeApprove(univ3Router, _cvx);
            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(cvx, poolFee, weth, poolFee, fxs),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _cvx,
                    amountOutMinimum: 0
                })
            );
        }

        // Step 3: Swap all FXS -> FRAX
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));

        if (_fxs > 0) {
            IERC20(fxs).safeApprove(univ3Router, 0);
            IERC20(fxs).safeApprove(univ3Router, _fxs);
            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(fxs, poolFee, frax),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _fxs,
                    amountOutMinimum: 0
                })
            );
        }

        uint256 _frax = IERC20(frax).balanceOf(address(this));

        // Treasury fees
        IERC20(frax).safeTransfer(
            IController(controller).treasury(),
            _frax.mul(performanceTreasuryFee).div(performanceTreasuryMax)
        );

        _frax = IERC20(frax).balanceOf(address(this));
        if (_frax > 0) {
            uint256[3] memory amounts;
            amounts[1] = _frax;
            IERC20(frax).safeApprove(CURVE_ZAP, 0);
            IERC20(frax).safeApprove(CURVE_ZAP, _frax);

            ICurveZap(CURVE_ZAP).add_liquidity(RSR_FRAXBP_POOL, amounts, 0);
        }
        deposit();
    }

    function totalWithdrawable() external view returns (uint256 _sum) {
        LockedStake[] memory lockedStakes = ICommunalFarm(FRAX_FARM).lockedStakesOf(convexPersonalVault);
        for (uint256 i = 0; i < lockedStakes.length; i++) {
            LockedStake memory stake = lockedStakes[i];
            if (stake.liquidity == 0 && block.timestamp < stake.ending_timestamp) continue;
            _sum = _sum.add(lockedStakes[i].liquidity);
        }
    }
}
