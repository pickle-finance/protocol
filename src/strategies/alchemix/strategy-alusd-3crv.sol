// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-alcx-farm-symbiotic.sol";

contract StrategyAlusd3Crv is StrategyAlcxSymbioticFarmBase {
    uint256 public alusd_3crv_poolId = 4;

    address public alusd_3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyAlcxSymbioticFarmBase(alusd_3crv_poolId, alusd_3crv, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyAlusd3Crv";
    }

    function getAlcxFarmHarvestable() public view returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalUnclaimed(address(this), alcxPoolId);
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Alcx tokens
        uint256 _alcxHarvestable = getAlcxFarmHarvestable();
        if (_alcxHarvestable > 0) IStakingPools(stakingPool).claim(alcxPoolId); //claim from alcx staking pool

        uint256 _harvestable = getHarvestable();
        if (_harvestable > 0) IStakingPools(stakingPool).claim(poolId); //claim from alusd_3crv staking pool

        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            // 10% is locked up for future gov
            uint256 _keepAlcx = _alcx.mul(keepAlcx).div(keepAlcxMax);
            IERC20(alcx).safeTransfer(IController(controller).treasury(), _keepAlcx);
            uint256 _amount = _alcx.sub(_keepAlcx);

            IERC20(alcx).safeApprove(stakingPool, 0);
            IERC20(alcx).safeApprove(stakingPool, _amount);
            IStakingPools(stakingPool).deposit(alcxPoolId, _amount); //stake to alcx farm
        }
    }

    function withdrawReward(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        address _jar = IController(controller).jars(address(want));
        address reward_token = IJar(_jar).reward();
        uint256 _balance = IERC20(alcx).balanceOf(address(this));
        uint256 _pendingReward = pendingReward();
        require(reward_token != address(0), "Reward token is not set in the pickle jar");
        require(reward_token == alcx, "Reward token is invalid");
        require(_pendingReward >= _amount, "[withdrawReward] Withdraw amount exceed redeemable amount");

        uint256 _alcxHarvestable = getAlcxFarmHarvestable();
        uint256 _harvestable = getHarvestable();

        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount && _alcxHarvestable > 0) IStakingPools(stakingPool).claim(alcxPoolId);
        
        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount && _harvestable > 0) IStakingPools(stakingPool).claim(poolId);

        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount) {
            uint256 _r = _amount.sub(_balance);
            uint256 _alcxDeposited = getAlcxDeposited();
            IStakingPools(stakingPool).withdraw(alcxPoolId, _alcxDeposited >= _r ? _r : _alcxDeposited);
        }
        _balance = IERC20(alcx).balanceOf(address(this));
        require(_balance >= _amount, "[WithdrawReward] Withdraw amount exceed balance"); //double check
        IERC20(reward_token).safeTransfer(_jar, _amount);
        __redeposit();
    }

    function getAlcxDeposited() public view override returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalDeposited(address(this), alcxPoolId);
    }

    function pendingReward() public view returns (uint256) {
        return
            IERC20(alcx).balanceOf(address(this)).add(IStakingPools(stakingPool).getStakeTotalDeposited(address(this), alcxPoolId).add(
                getHarvestable().add(getAlcxFarmHarvestable()))
            );
    }
}
