// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-alcx-farm-base.sol";

contract StrategyCurveAlusd3Crv is StrategyAlchemixFarmBase {

    uint256 public alusd_3crv_poolId = 4;

    address public alusd_3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAlchemixFarmBase(
            alusd_3crv_poolId,
            alusd_3crv,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(alcx).approve(stakingPool, uint(-1));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCurveAlusd3Crv";
    }

    function getAlcxFarmHarvestable() public view returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalUnclaimed(address(this), alcxPoolId);
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Alcx tokens
        uint256 _alcxHarvestable = getAlcxFarmHarvestable();
        if (_alcxHarvestable > 0) IStakingPools(stakingPool).claim(alcxPoolId);    //claim from alcx staking pool
        
        uint256 _harvestable = getHarvestable();
        if (_harvestable > 0) IStakingPools(stakingPool).claim(poolId); //claim from alusd_3crv staking pool

        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            // 10% is locked up for future gov
            uint256 _keepAlcx = _alcx.mul(keepAlcx).div(keepAlcxMax);
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                _keepAlcx
            );
            uint256 _amount = _alcx.sub(_keepAlcx);
            IStakingPools(stakingPool).deposit(alcxPoolId, _amount); //stake to alcx farm
        }
    }

    function _withdrawToJar(uint256 _amount) internal returns(uint256) {
        address _jar = getJarAddress();
        address reward_token = IJar(_jar).reward();
        require (reward_token != address(0), "Reward token is not set in the pickle jar");
        
        uint256 _rewardAmount = (getRedeemableReward().mul(_amount))
                                .div(IJar(_jar).totalSupply().add(_amount)); //add missing shares
        _withdrawSomeReward(_rewardAmount);
        uint256 _reward_balance = IERC20(reward_token).balanceOf(address(this));
        
        if (_reward_balance < _rewardAmount) _rewardAmount = _reward_balance;

        uint256 _feeDev = _rewardAmount.mul(withdrawalDevFundFee).div(
            withdrawalDevFundMax
        );
        IERC20(reward_token).safeTransfer(IController(controller).devfund(), _feeDev);

        uint256 _feeTreasury = _rewardAmount.mul(withdrawalTreasuryFee).div(
            withdrawalTreasuryMax
        );

        IERC20(reward_token).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        uint256 _send_amount = _rewardAmount.sub(_feeDev).sub(_feeTreasury);

        IERC20(reward_token).safeTransfer(_jar, _send_amount);
        return _send_amount;
    }
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        _withdrawToJar(_amount);
        address _jar = getJarAddress();
        uint256 r = (IJar(_jar).balance().mul(_amount)).div(IJar(_jar).totalSupply().add(_amount)); //add missing amount because it is already burned
        uint256 _want_amount = r.sub(IERC20(want).balanceOf(_jar)); //sub existing want balance
        IStakingPools(stakingPool).withdraw(poolId, _want_amount);

        return _want_amount;
    }

    function getJarAddress() public view returns (address) {        
        address _jar = IController(controller).jars(address(want));        
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        return _jar;
    }

    function _withdrawSomeReward(uint256 _amount)
        internal
        returns (uint256)
    {
        IStakingPools(stakingPool).withdraw(alcxPoolId, _amount);
        return _amount;
    }

    function getRedeemableReward() public view returns (uint256) {       
        return IStakingPools(stakingPool).getStakeTotalDeposited(address(this), alcxPoolId);
    }
}
