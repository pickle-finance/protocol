// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/chainlink/AutomationCompatibleInterface.sol";
import "./interfaces/strategyv2.sol";
import "./interfaces/univ3/pool/IUniswapV3PoolState.sol";


contract PickleRebalancingKeeper is AutomationCompatibleInterface {
    address[] public strategies;
    address public keeperRegistry = 0x75c0530885F385721fddA23C539AF3701d6183D4;
    int24 public threshold = 10;

    address public governance;
    bool public disabled = false;

    modifier onlyGovernance() {
        require(msg.sender == governance, "!Governance");
        _;
    }

    modifier whenNotDisabled() {
        require(!disabled, "Disabled");
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setKeeperRegistry(address _keeperRegistry) external onlyGovernance {
        keeperRegistry = _keeperRegistry;
    }

    function setThreshold(int24 _threshold) external onlyGovernance {
        threshold = _threshold;
    }

    function setDisabled(bool _disabled) external onlyGovernance {
        disabled = _disabled;
    }

    function addStrategy(address _address) external onlyGovernance {
        require(!_search(_address), "Address Already Watched");
        strategies.push(_address);
    }

    function removeStrategy(address _address) external onlyGovernance {
        require(_search(_address), "Address Not Watched");

        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == _address) {
                strategies[i] = strategies[strategies.length - 1];
                strategies.pop();
                break;
            }
        }
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        whenNotDisabled
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory _stratsToUpkeep = new address[](strategies.length);

        uint24 counter = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            bool shouldRebalance = _checkValidToCall(strategies[i]);
            if (shouldRebalance == true) {
                _stratsToUpkeep[counter] = strategies[i];
                upkeepNeeded = true;
                counter++;
            }
        }

        if (upkeepNeeded == true) {
            address[] memory stratsToUpkeep = new address[](counter);
            for (uint i = 0; i < counter; i++) {
                stratsToUpkeep[i] = _stratsToUpkeep[i];
            }
            performData = abi.encode(stratsToUpkeep);
        }
    }

    function performUpkeep(bytes calldata performData) external override whenNotDisabled {
        address[] memory stratsToUpkeep = abi.decode(performData, (address[]));

        for (uint24 i = 0; i < stratsToUpkeep.length; i++) {
            require(_checkValidToCall(stratsToUpkeep[i]), "!Valid");
            IStrategyV2(stratsToUpkeep[i]).rebalance();
        }
    }

    function _search(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function _checkValidToCall(address _strategy) internal view returns (bool) {
        require(_search(_strategy), "Address Not Watched");

        int24 _lowerTick = IStrategyV2(_strategy).tick_lower();
        int24 _upperTick = IStrategyV2(_strategy).tick_upper();
        int24 _range = _upperTick - _lowerTick;
        int24 _limitVar = _range / threshold;
        int24 _lowerLimit = _lowerTick + _limitVar;
        int24 _upperLimit = _upperTick - _limitVar;

        (, int24 _currentTick, , , , , ) = IUniswapV3PoolState(IStrategyV2(_strategy).pool()).slot0();
        if (_currentTick < _lowerLimit || _currentTick > _upperLimit) {
            return true;
        }
        return false;
    }
}
