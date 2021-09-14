interface IRewards {
    function getReward() external;
}

contract GlobalHarvester {
    function getRewards(address[] calldata gauges) external {
        for(uint256 i = 0; i < gauges.length; i++){
            if(gauges[i] == address(0)) break;
            IRewards(gauges[i]).getReward();
        }
    }
}
