// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ProtocolGovernance.sol";

interface IGaugeMiddleware {
    function addGauge(address _token, address _governance)
        external
        returns (address);
}

interface IVirtualGaugeMiddleware {
    function addVirtualGauge(address _jar, address _governance)
        external
        returns (address);
}

interface IRootChainGaugeMiddleware {
    function addRootChainGauge() external returns (address);
}

interface iGaugeV2 {
    function notifyRewardAmount(
        address[] memory rewarders,
        uint256[] memory rewards
    ) external;
}

interface MasterChef {
    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256, uint256);
}

contract MasterDill {
    /// @notice EIP-20 token name for this token
    string public constant name = "Master DILL";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "mDILL";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 1e18;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor() {
        balances[msg.sender] = 1e18;
        emit Transfer(address(0x0), msg.sender, 1e18);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        require(
            amount <= spenderAllowance,
            "transferFrom: exceeds spender allowance"
        );

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");
        require(amount <= balances[src], "_transferTokens: exceeds balance");

        balances[src] -= amount;
        balances[dst] += amount;
        emit Transfer(src, dst, amount);
    }
}

contract GaugeProxyV2 is ProtocolGovernance, Initializable {
    using SafeERC20 for IERC20;

    MasterChef public constant MASTER =
        MasterChef(0xbD17B1ce622d73bD438b9E658acA5996dc394b0d);
    IERC20 public constant DILL =
        IERC20(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf);
    IERC20 public constant PICKLE =
        IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);

    IERC20 public TOKEN;

    uint256 public pid;

    address[] internal _tokens;

    uint256 private _gaugeTypeCounter;

    // token => gauge
    mapping(address => address) public gauges;
    mapping(address => uint256) public gaugeWithNegativeWeight;
    mapping(address => bool) public isVirtualGauge;
    mapping(uint256 => string) public gaugeTypeIds;
    mapping(address => uint256) public gaugeToGaugeType;
    mapping(uint256 => mapping(uint256 => int256)) public gaugeTypeWeights;

    uint256 public constant WEEK_SECONDS = 604800;
    // epoch time stamp
    uint256 public firstDistribution;
    uint256 public distributionId;
    uint256 public lastVotedPeriodId;

    mapping(address => uint256) public tokenLastVotedPeriodId; // token => last voted period id
    mapping(address => int256) public usedWeights; // msg.sender => total voting weight of user
    mapping(address => address[]) public tokenVote; // msg.sender => token
    mapping(address => mapping(address => int256)) public votes; // msg.sender => votes
    mapping(uint256 => mapping(address => int256)) public weights; // period id => token => weight
    mapping(uint256 => int256) public totalWeight; // period id => TotalWeight
    mapping(uint256 => mapping(uint256 => bool)) public distributed;
    mapping(uint256 => uint256) public periodForDistribute; // dist id => which period id votes to use
    IGaugeMiddleware public gaugeMiddleware;
    IVirtualGaugeMiddleware public virtualGaugeMiddleware;
    IRootChainGaugeMiddleware public rootChainGaugeMiddleware;

    struct delegateData {
        // delegated address
        address delegate;
        // previous delegated address if updated, else zero address
        address prevDelegate;
        // period id when delegate address was updated
        uint256 updatePeriodId;
        // endPeriod if defined. Else 0.
        uint256 endPeriod;
        // If no endPeriod
        bool indefinite;
        // Period => Boolean (if delegate address can vote in that period)
        mapping(uint256 => bool) blockDelegate;
    }

    mapping(address => delegateData) public delegations;

    function getCurrentPeriodId() public view returns (uint256) {
        return
            block.timestamp > firstDistribution
                ? ((block.timestamp - firstDistribution) / WEEK_SECONDS) + 1
                : 0;
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    function initialize(uint256 _firstDistribution) public initializer {
        TOKEN = IERC20(address(new MasterDill()));
        governance = msg.sender;
        firstDistribution = _firstDistribution;
        distributionId = 1;
        lastVotedPeriodId = 1;
        periodForDistribute[1] = 1;
        _gaugeTypeCounter = 1;
        // default chain gauge type current id is 1, _gaugeTypeCounterId is 1 and weight is 1;
        gaugeTypeWeights[1][1] = 1;
    }

    function addGaugeMiddleware(address _gaugeMiddleware) external {
        require(
            _gaugeMiddleware != address(0),
            "gaugeMiddleware cannot set to zero"
        );
        require(
            _gaugeMiddleware != address(gaugeMiddleware),
            "current and new gaugeMiddleware are same"
        );
        require(msg.sender == governance, "!gov");
        gaugeMiddleware = IGaugeMiddleware(_gaugeMiddleware);
    }

    function addVirtualGaugeMiddleware(address _virtualGaugeMiddleware)
        external
    {
        require(
            _virtualGaugeMiddleware != address(0),
            "virtualGaugeMiddleware cannot set to zero"
        );
        require(
            _virtualGaugeMiddleware != address(virtualGaugeMiddleware),
            "current and new virtualGaugeMiddleware are same"
        );
        require(msg.sender == governance, "!gov");
        virtualGaugeMiddleware = IVirtualGaugeMiddleware(
            _virtualGaugeMiddleware
        );
    }

    function addRootChainGaugeMiddleware(address _rootChainGaugeMiddleware)
        external
    {
        require(
            _rootChainGaugeMiddleware != address(0),
            "virtualGaugeMiddleware cannot set to zero"
        );
        require(
            _rootChainGaugeMiddleware != address(rootChainGaugeMiddleware),
            "current and new rootChainGaugeMiddleware are same"
        );
        require(msg.sender == governance, "!gov");
        rootChainGaugeMiddleware = IRootChainGaugeMiddleware(
            _rootChainGaugeMiddleware
        );
    }

    function setTypeWeight(uint256 _gaugeTypeId, int256 weight) external {
        require(msg.sender == governance, "!gov");
        require(
            _gaugeTypeId > 0 && _gaugeTypeId <= _gaugeTypeCounter,
            "invalid gauge type id"
        );
        gaugeTypeWeights[getCurrentPeriodId()][_gaugeTypeId] = weight;

        emit GaugeTypeWeightUpdated(_gaugeTypeId, weight);
    }

    // Reset votes to 0
    function reset() external {
        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        _reset(msg.sender, currentId);
    }

    // Reset votes to 0
    function _reset(address _owner, uint256 _currentId) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;
        require(_currentId > 0, "Voting not started");

        if (_currentId > lastVotedPeriodId) {
            totalWeight[_currentId] = totalWeight[lastVotedPeriodId];
            lastVotedPeriodId = _currentId;
        }

        for (uint256 i = 0; i < _tokenVoteCnt; i++) {
            address _token = _tokenVote[i];
            int256 _votes = votes[_owner][_token];

            if (_votes != 0) {
                totalWeight[_currentId] -= (_votes > 0 ? _votes : -_votes);
                if (_currentId > tokenLastVotedPeriodId[_token]) {
                    weights[_currentId][_token] = weights[
                        tokenLastVotedPeriodId[_token]
                    ][_token];

                    tokenLastVotedPeriodId[_token] = _currentId;
                }

                weights[_currentId][_token] -= _votes;
                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
        // Ensure distribute _rewards are for current period
        periodForDistribute[_currentId] = _currentId;
    }

    // Adjusts _owner's votes according to latest _owner's DILL balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        int256[] memory _weights = new int256[](_tokenCnt);
        uint256 currentId = getCurrentPeriodId();

        int256 _prevUsedWeight = usedWeights[_owner];
        int256 _weight = int256(DILL.balanceOf(_owner));

        for (uint256 i = 0; i < _tokenCnt; i++) {
            int256 _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = (_prevWeight * (_weight)) / (_prevUsedWeight);
        }
        _vote(_owner, _tokenVote, _weights, currentId);
    }

    function _vote(
        address _owner,
        address[] memory _tokenVote,
        int256[] memory _weights,
        uint256 _currentId
    ) internal {
        _reset(_owner, _currentId);
        uint256 _tokenCnt = _tokenVote.length;
        int256 _weight = int256(DILL.balanceOf(_owner));
        int256 _totalVoteWeight = 0;
        int256 _totalTypeWeight = 0;
        address[] memory gaugesData = new address[](_tokenCnt);
        int256[] memory gaugeTypeWeightByCurrentId = new int256[](_tokenCnt);
        int256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _totalVoteWeight += (_weights[i] > 0 ? _weights[i] : -_weights[i]);
            gaugesData[i] = gauges[_tokenVote[i]];
            gaugeTypeWeightByCurrentId[i] = gaugeTypeWeights[_currentId][
                gaugeToGaugeType[gaugesData[i]]
            ];
            _totalTypeWeight += gaugeTypeWeightByCurrentId[i];
        }

        for (uint256 i = 0; i < _tokenCnt; i++) {
            int256 _tokenWeight = (_weights[i] *
                gaugeTypeWeightByCurrentId[i] *
                _weight) / (_totalVoteWeight * _totalTypeWeight);

            if (gaugesData[i] != address(0x0)) {
                weights[_currentId][_tokenVote[i]] += _tokenWeight;
                votes[_owner][_tokenVote[i]] = _tokenWeight;
                tokenVote[_owner].push(_tokenVote[i]);

                if (_tokenWeight < 0) _tokenWeight = -_tokenWeight;

                _usedWeight += _tokenWeight;
                totalWeight[_currentId] += _tokenWeight;
            }
        }
        usedWeights[_owner] = _usedWeight;
    }

    // Vote with DILL on a gauge
    function vote(address[] calldata _tokenVote, int256[] calldata _weights)
        external
    {
        require(
            _tokenVote.length == _weights.length,
            "GaugeProxy: token votes count does not match weights count"
        );
        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        _vote(msg.sender, _tokenVote, _weights, currentId);
        delegations[msg.sender].blockDelegate[currentId] = true;
    }

    function setVotingDelegate(
        address _delegateAddress,
        uint256 _periodsCount,
        bool _indefinite
    ) external {
        require(
            _delegateAddress != address(0),
            "GaugeProxyV2: cannot delegate zero address"
        );
        require(
            _delegateAddress != msg.sender,
            "GaugeProxyV2: delegate address cannot be delegating"
        );

        delegateData storage _delegate = delegations[msg.sender];

        uint256 currentPeriodId = getCurrentPeriodId();

        address currentDelegate = _delegate.delegate;
        _delegate.delegate = _delegateAddress;
        _delegate.prevDelegate = currentDelegate;
        _delegate.updatePeriodId = currentPeriodId;

        if (_indefinite == true) {
            _delegate.indefinite = true;
        } else if (_delegate.prevDelegate == address(0)) {
            _delegate.endPeriod = currentPeriodId + _periodsCount - 1;
        } else {
            _delegate.endPeriod = currentPeriodId + _periodsCount;
        }
    }

    function voteFor(
        address _owner,
        address[] calldata _tokenVote,
        int256[] calldata _weights
    ) external {
        require(
            _tokenVote.length == _weights.length,
            "GaugeProxy: token votes count does not match weights count"
        );

        uint256 currentId = getCurrentPeriodId();
        require(currentId > 0, "Voting not started yet");
        delegateData storage _delegate = delegations[_owner];
        require(
            (_delegate.delegate == msg.sender &&
                currentId > _delegate.updatePeriodId) ||
                (_delegate.prevDelegate == msg.sender &&
                    currentId == _delegate.updatePeriodId) ||
                (_delegate.prevDelegate == address(0) &&
                    currentId == _delegate.updatePeriodId),
            "Sender not authorized"
        );
        require(
            _delegate.blockDelegate[currentId] == false,
            "Delegating address has already voted"
        );
        require(
            (_delegate.indefinite || currentId <= _delegate.endPeriod),
            "Delegating period expired"
        );

        _vote(_owner, _tokenVote, _weights, currentId);
    }

    // Add new token gauge
    function addGauge(address _token) external {
        require(msg.sender == governance, "!gov");
        require(
            address(gaugeMiddleware) != address(0),
            "cannot add new gauge without initializing gaugeMiddleware"
        );
        require(gauges[_token] == address(0x0), "exists");
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(PICKLE);
        gauges[_token] = gaugeMiddleware.addGauge(_token, governance);
        gaugeToGaugeType[_token] = 1;
        _tokens.push(_token);
    }

    function addRootChainGauge(address _token, uint256 _gaugeTypeId) external {
        require(msg.sender == governance, "!gov");
        require(
            address(gaugeMiddleware) != address(0),
            "cannot add new gauge without initializing gaugeMiddleware"
        );
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = rootChainGaugeMiddleware.addRootChainGauge();
        gaugeToGaugeType[_token] = _gaugeTypeId;
        _tokens.push(_token);
    }

    function addGaugeType(string calldata name) external {
        require(msg.sender == governance, "!gov");
        uint256 gaugeTypeCounter = _gaugeTypeCounter;
        gaugeTypeCounter += 1;
        gaugeTypeIds[gaugeTypeCounter] = name;
        _gaugeTypeCounter = gaugeTypeCounter;
        gaugeTypeWeights[getCurrentPeriodId()][gaugeTypeCounter] = 1;
        emit NewGaugeType(gaugeTypeCounter, name, 1);
    }

    // Add new token virtual gauge
    function addVirtualGauge(address _token, address _jar) external {
        require(msg.sender == governance, "!gov");
        require(
            address(gaugeMiddleware) != address(0),
            "cannot add new gauge without initializing gaugeMiddleware"
        );
        require(gauges[_token] == address(0x0), "exists");
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(PICKLE);
        address vgauge = virtualGaugeMiddleware.addVirtualGauge(
            _jar,
            governance
        );
        gauges[_token] = vgauge;
        isVirtualGauge[vgauge] = true;
        gaugeToGaugeType[_token] = 1;
        _tokens.push(_token);
    }

    function delistGauge(address _token) external {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] != address(0x0), "!exists");

        uint256 currentId = getCurrentPeriodId();
        require(distributionId == currentId, "! all distributions completed");

        address _gauge = gauges[_token];

        require(gaugeWithNegativeWeight[_gauge] >= 5, "censors < 5");

        delete isVirtualGauge[_gauge];
        delete gauges[_token];

        uint256 tokensLength = _tokens.length;
        address[] memory newTokenArray = new address[](tokensLength - 1);

        uint256 j = 0;
        for (uint256 i = 0; i < tokensLength; i++) {
            if (_tokens[i] != _token) {
                newTokenArray[j] = _tokens[i];
                j++;
            }
        }

        _tokens = newTokenArray;
    }

    // Sets MasterChef PID
    function setPID(uint256 _pid) external {
        require(msg.sender == governance, "!gov");
        require(pid == 0, "pid has already been set");
        require(_pid > 0, "invalid pid");
        pid = _pid;
    }

    // Deposits mDILL into MasterChef
    function deposit() public {
        require(pid > 0, "pid not initialized");
        IERC20 _token = TOKEN;
        uint256 _balance = _token.balanceOf(address(this));
        _token.safeApprove(address(MASTER), 0);
        _token.safeApprove(address(MASTER), _balance);
        MASTER.deposit(pid, _balance);
    }

    // Fetches Pickle
    function collect() public {
        (uint256 _locked, ) = MASTER.userInfo(pid, address(this));
        MASTER.withdraw(pid, _locked);
        deposit();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function distribute(uint256 _start, uint256 _end) external {
        require(_start < _end, "GaugeProxyV2: bad _start");
        require(_end <= _tokens.length, "GaugeProxyV2: bad _end");
        require(
            msg.sender == governance,
            "GaugeProxyV2: only governance can distribute"
        );

        uint256 currentId = getCurrentPeriodId();
        require(
            distributionId < currentId,
            "GaugeProxyV2: all period distributions complete"
        );

        uint256 periodToUse = 0;
        if (periodForDistribute[distributionId] == 0) {
            // If period does not exist means no votes in this period
            // Use previous period's votes and update dist. period
            periodToUse = periodForDistribute[distributionId - 1];
            periodForDistribute[distributionId] = periodForDistribute[
                distributionId - 1
            ];
        } else {
            periodToUse = periodForDistribute[distributionId];
        }

        collect();
        int256 _balance = int256(PICKLE.balanceOf(address(this)));
        int256 _totalWeight = totalWeight[periodToUse];

        if (_balance > 0 && _totalWeight > 0) {
            for (uint256 i = _start; i < _end; i++) {
                if (distributed[distributionId][i]) {
                    continue;
                }
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                int256 _reward = (_balance * weights[periodToUse][_token]) /
                    _totalWeight;
                if (_reward > 0) {
                    uint256 reward_ = uint256(_reward);
                    uint256[] memory rewardArr = new uint256[](1);
                    address[] memory _rewarder = new address[](1);
                    rewardArr[0] = reward_;
                    _rewarder[0] = address(this);

                    PICKLE.safeApprove(_gauge, 0);
                    PICKLE.safeApprove(_gauge, reward_);

                    iGaugeV2(_gauge).notifyRewardAmount(_rewarder, rewardArr);
                }

                if (_reward < 0) {
                    gaugeWithNegativeWeight[_gauge] += 1;
                }
                distributed[distributionId][i] = true;
            }
        }
        if (_tokens.length == _end) {
            distributionId += 1;
        }
    }

    event NewGaugeType(uint256 gaugeTypeId, string indexed name, int256 weight);
    event GaugeTypeWeightUpdated(uint256 indexed gaugeTypeId, int256 weight);
}
