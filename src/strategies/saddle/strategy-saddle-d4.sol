pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../interfaces/saddle-farm.sol";

contract StrategySaddleD4 is StrategyBase {
    address public staking = 0x0639076265e9f88542C91DCdEda65127974A5CA5;
    address public saddle_d4lp = 0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A;

    address public alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address public frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public fei = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    address public alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
    address public fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public tribe = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;
    address public lqty = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;

    address public flashLoan = 0xC69DDcd4DFeF25D8a793241834d4cc4b3668EAD6;

    address public constant univ3Router =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 public constant poolFee = 3000;

    // Uniswap swap paths
    address[] public fxs_frax_path;
    address[] public tribe_fei_path;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            saddle_d4lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        fxs_frax_path = new address[](2);
        fxs_frax_path[0] = fxs;
        fxs_frax_path[1] = frax;

        tribe_fei_path = new address[](2);
        tribe_fei_path[0] = tribe;
        tribe_fei_path[1] = fei;
    }

    function getName() external pure override returns (string memory) {
        return "StrategySaddleD4";
    }

    function balanceOfPool() public view override returns (uint256) {
        return ICommunalFarm(staking).lockedLiquidityOf(address(this));
    }

    function getHarvestable() public view returns (uint256[] memory) {
        return ICommunalFarm(staking).earned(address(this));
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 _min = ICommunalFarm(staking).lock_time_min();
            IERC20(want).safeApprove(staking, 0);
            IERC20(want).safeApprove(staking, _want);
            ICommunalFarm(staking).stakeLocked(_want, _min);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        LockedStake[] memory lockedStakes = ICommunalFarm(staking)
            .lockedStakesOf(address(this));
        uint256 _sum = 0;
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < lockedStakes.length; i++) {
            _sum = _sum.add(lockedStakes[i].liquidity);
            count++;
            if (_sum >= _amount) break;
        }
        require(_sum >= _amount, "insufficient amount");

        for (i = 0; i < count; i++) {
            ICommunalFarm(staking).withdrawLocked(lockedStakes[i].kek_id);
        }
        uint256 _balance = IERC20(want).balanceOf(address(this));
        require(_balance >= _amount, "withdraw-failed");

        return _amount;
    }

    function harvest() public override onlyBenevolent {
        deposit();
        ICommunalFarm(staking).getReward();

        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_fxs > 0) {
            IERC20(fxs).safeApprove(univ2Router2, 0);
            IERC20(fxs).safeApprove(univ2Router2, _fxs);
            _swapUniswapWithPath(fxs_frax_path, _fxs);
        }

        uint256 _tribe = IERC20(tribe).balanceOf(address(this));
        if (_tribe > 0) {
            IERC20(tribe).safeApprove(univ2Router2, 0);
            IERC20(tribe).safeApprove(univ2Router2, _tribe);
            _swapUniswapWithPath(tribe_fei_path, _tribe);
        }

        uint256 _lqty = IERC20(lqty).balanceOf(address(this));
        if (_lqty > 0) {
            IERC20(lqty).safeApprove(univ2Router2, 0);
            IERC20(lqty).safeApprove(univ2Router2, _lqty);
            _swapUniswap(lqty, lusd, _lqty);
        }

        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            IERC20(alcx).safeApprove(sushiRouter, 0);
            IERC20(alcx).safeApprove(sushiRouter, _alcx);
            _swapSushiswap(alcx, alusd, _alcx);
        }

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = IERC20(alusd).balanceOf(address(this));
        amounts[1] = IERC20(fei).balanceOf(address(this));
        amounts[2] = IERC20(frax).balanceOf(address(this));
        amounts[3] = IERC20(lusd).balanceOf(address(this));

        if (
            amounts[0] > 0 || amounts[1] > 0 || amounts[2] > 0 || amounts[3] > 0
        ) {
            if (amounts[0] > 0) {
                IERC20(alusd).safeApprove(flashLoan, 0);
                IERC20(alusd).safeApprove(flashLoan, amounts[0]);
            }
            if (amounts[1] > 0) {
                IERC20(fei).safeApprove(flashLoan, 0);
                IERC20(fei).safeApprove(flashLoan, amounts[1]);
            }
            if (amounts[2] > 0) {
                IERC20(frax).safeApprove(flashLoan, 0);
                IERC20(frax).safeApprove(flashLoan, amounts[2]);
            }
            if (amounts[3] > 0) {
                IERC20(lusd).safeApprove(flashLoan, 0);
                IERC20(lusd).safeApprove(flashLoan, amounts[3]);
            }

            SwapFlashLoan(flashLoan).addLiquidity(
                amounts,
                0,
                block.timestamp.add(300)
            );
        }
        _distributePerformanceFeesAndDeposit();
    }
}
