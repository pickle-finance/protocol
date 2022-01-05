// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/chainlink/KeeperCompatible.sol";
import "../interfaces/strategyv2.sol";
import "./interfaces/univ3/pool/IUniswapV3PoolState.sol";

contract PickleRebalancingKeeper is KeeperCompatibleInterface {
    address[] public strategyArray;
    int24 public threshold = 10;

    address public governance;
    bool public disabled = false;

    constructor(address _governance) public {
        governance = _governance;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setThreshold(int24 _threshold) external {
        require(msg.sender == governance, "!governance");
        threshold = _threshold;
    }

    function setDisabled(bool _disabled) external {
        require(msg.sender == governance, "!governance");
        disabled = _disabled;
    }

    function addStrategy(address _address) external {
        require(msg.sender == governance, "!governance");
        require(!_search(_address), "Address Already Watched");
        strategyArray.push(_address);
    }

    function removeStrategy(address _address) external {
        require(msg.sender == governance, "!governance");
        require(_search(_address), "Address Not Watched");

        for (uint256 i = 0; i < strategyArray.length; i++) {
            if (strategyArray[i] == _address) {
                strategyArray[i] = strategyArray[strategyArray.length - 1];
                strategyArray.pop();
                break;
            }
        }
    }

    function checkUpkeep(bytes calldata)
        external
        override
        returns (
            bool,
            bytes memory _memory
        )
    {
      require(!disabled, "Disabled");

        for (uint256 i = 0; i < strategyArray.length; i++) {
            int24 _lowerTick = IStrategyV2(strategyArray[i]).tick_lower();
            int24 _upperTick = IStrategyV2(strategyArray[i]).tick_upper();
            int24 _range = _upperTick - _lowerTick;
            int24 _limitVar = _range / threshold;
            int24 _lowerLimit = _lowerTick + _limitVar;
            int24 _upperLimit = _upperTick - _limitVar;

            (, int24 _currentTick, , , , , ) = IUniswapV3PoolState(
                IStrategyV2(strategyArray[i]).pool()
            ).slot0();
            if (_currentTick < _lowerLimit || _currentTick > _upperLimit) {
                return (true, abi.encode(strategyArray[i]));
            }
        }
        return (false, _memory);
    }

    function performUpkeep(bytes memory _calldata) external override {
        require(!disabled, "Disabled");
        address _strategy = abi.decode(_calldata, (address));
        IStrategyV2(_strategy).rebalance();
    }

    function _search(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < strategyArray.length; i++) {
            if (strategyArray[i] == _address) {
                return true;
            }
        }
        return false;
    }
}
