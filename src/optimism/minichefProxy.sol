// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PoolInfo {
    uint128 accPicklePerShare;
    uint64 lastRewardTime;
    uint64 allocPoint;
}

interface IMiniChef {
    function add(
        uint256 allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setPicklePerSecond(uint256 _picklePerSecond) external;

    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    function massUpdatePools(uint256[] calldata pids) external;

    function poolLength() external view returns (uint256 pools);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function claimOwnership() external;
}

interface IRewarder {
    function setRewardPerSecond(uint256 _rewardPerSecond) external;

    function add(uint256 allocPoint, uint256 _pid) external;

    function set(uint256 _pid, uint256 _allocPoint) external;

    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    function massUpdatePools(uint256[] calldata pids) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function claimOwnership() external;
}

contract ChefProxy {
    address public governance;
    address public pendingGovernance;

    address[] public strategists;
    mapping(address => bool) public isStrategist;

    IMiniChef public MINICHEF;
    IRewarder public REWARDER;

    modifier onlyGovernance() {
        require(msg.sender == governance, "!Governance");
        _;
    }

    modifier onlyStrategist() {
        require(isStrategist[msg.sender], "!Strategist");
        _;
    }

    constructor(IMiniChef _minichef, IRewarder _rewarder) {
        governance = msg.sender;
        MINICHEF = _minichef;
        REWARDER = _rewarder;
    }

    function setPendingGovernance(address _newGovernance) external onlyGovernance {
        pendingGovernance = _newGovernance;
    }

    function claimGovernance() external {
        require(msg.sender == pendingGovernance, "!pendingGovernance");
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    function addStrategist(address _newStrategist) external onlyGovernance {
        require(!isStrategist[msg.sender], "Already a strategist");

        strategists.push(_newStrategist);
        isStrategist[_newStrategist] = true;
    }

    function removeStrategist(address _strategist) external onlyGovernance {
        require(isStrategist[_strategist], "!Strategist");

        for (uint256 i = 0; i < strategists.length; i++) {
            if (strategists[i] == _strategist) {
                strategists[i] = strategists[strategists.length - 1];
                strategists.pop();
                break;
            }
        }
        isStrategist[_strategist] = false;
    }

    function setMinichef(IMiniChef _newMinichef) external onlyGovernance {
        MINICHEF = _newMinichef;
    }

    function setRewarder(IRewarder _newRewarder) external onlyGovernance {
        REWARDER = _newRewarder;
    }

    ///@notice set an address as pendingOwner on the minichef
    function transferMinichefOwnership(address _newOwner) external onlyGovernance {
        MINICHEF.transferOwnership(_newOwner, false, false);
    }

    ///@notice claims ownership of the minichef
    function claimMinichefOwnership() external onlyGovernance {
        MINICHEF.claimOwnership();
    }

    ///@notice set an address as pendingOwner on the rewarder
    function transferRewarderOwnership(address _newOwner) external onlyGovernance {
        REWARDER.transferOwnership(_newOwner, false, false);
    }

    ///@notice claims ownership of the rewarder
    function claimRewarderOwnership() external onlyGovernance {
        REWARDER.claimOwnership();
    }

    function setPicklePerSecond(uint256 _picklePerSecond) external onlyStrategist {
        MINICHEF.setPicklePerSecond(_picklePerSecond);
    }

    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyStrategist {
        REWARDER.setRewardPerSecond(_rewardPerSecond);
    }

    ///@notice Add multiple LPs to minichef and rewarder
    function add(address[] calldata _lpTokens, uint256[] calldata _allocPoints) external onlyStrategist {
        require(_lpTokens.length == _allocPoints.length, "!match");

        uint256 poolLength = MINICHEF.poolLength();

        for (uint256 i = 0; i < _lpTokens.length; i++) {
            MINICHEF.add(_allocPoints[i], _lpTokens[i], address(REWARDER));
            REWARDER.add(_allocPoints[i], poolLength + i);
        }
    }

    ///@notice Update the allocPoints for multiple pools on minichef and rewarder
    function set(uint256[] calldata _pids, uint256[] calldata _allocPoints) external onlyStrategist {
        require(_pids.length == _allocPoints.length, "!match");

        for (uint256 i = 0; i < _pids.length; i++) {
            MINICHEF.set(_pids[i], _allocPoints[i], address(REWARDER), false);
            REWARDER.set(_pids[i], _allocPoints[i]);
        }
    }

    ///@notice An emergency function for the governance to execute calls that are not supported by this contract (e.g, renounce chef ownership to address(0))
    function execute(
        address target,
        string calldata signature,
        bytes calldata data
    ) external onlyGovernance returns (bytes memory returnData) {
        bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

        bool success;
        (success, returnData) = target.call(callData);
        require(success, "execute failed");
    }
}
