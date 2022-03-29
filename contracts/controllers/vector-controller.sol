// https://github.com/iearn-finance/globes/blob/master/contracts/controllers/StrategyControllerV1.sol

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../interfaces/controller.sol";

import "../lib/erc20.sol";
import "../lib/safe-math.sol";

import "../interfaces/globe.sol";
import "../interfaces/globe-converter.sol";
import "../interfaces/onesplit.sol";
import "../interfaces/strategy.sol";
import "../interfaces/converter.sol";

contract VectorControllerV4 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant burn = 0x000000000000000000000000000000000000dEaD;
    address public onesplit = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    address public governance;
    address public strategist;
    address public devfund;
    address public treasury;
    address public timelock;

    // Convenience fee 0.1%
    uint256 public convenienceFee = 100;
    uint256 public constant convenienceFeeMax = 100000;

    mapping(address => address) public globes; // takes lp address and returns associated globe
    mapping(address => address) public strategies; // takes lp and returns associated strategy
    mapping(address => mapping(address => address)) public converters;
    mapping(address => mapping(address => bool)) public approvedStrategies;
    mapping(address => bool) public approvedGlobeConverters;

    uint256 public split = 500;
    uint256 public constant max = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _timelock,
        address _devfund,
        address _treasury
    ) public {
        governance = _governance;
        strategist = _strategist;
        timelock = _timelock;
        devfund = _devfund;
        treasury = _treasury;
    }

    function setDevFund(address _devfund) public {
        require(msg.sender == governance, "!governance");
        devfund = _devfund;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setSplit(uint256 _split) public {
        require(msg.sender == governance, "!governance");
        require(_split <= max, "numerator cannot be greater than denominator");
        split = _split;
    }

    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setGlobe(address _token, address _globe) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(globes[_token] == address(0), "globe");
        globes[_token] = _globe;
    }

    function approveGlobeConverter(address _converter) public {
        require(msg.sender == governance, "!governance");
        approvedGlobeConverters[_converter] = true;
    }

    function revokeGlobeConverter(address _converter) public {
        require(msg.sender == governance, "!governance");
        approvedGlobeConverters[_converter] = false;
    }

    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == timelock, "!timelock");
        approvedStrategies[_token][_strategy] = true;
    }

    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(strategies[_token] != _strategy, "cannot revoke active strategy");
        approvedStrategies[_token][_strategy] = false;
    }

    function setConvenienceFee(uint256 _convenienceFee) external {
        require(msg.sender == timelock, "!timelock");
        convenienceFee = _convenienceFee;
    }

    function setStrategy(address _token, address _strategy) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = Converter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
        public
    {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IStrategy(_strategy).withdraw(_token);
    }

    function getExpectedReturn(
        address _strategy,
        address _token,
        uint256 parts
    ) public view returns (uint256 expected) {
        uint256 _balance = IERC20(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected, ) = OneSplitAudit(onesplit).getExpectedReturn(
            _token,
            _want,
            _balance,
            parts,
            0
        );
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function yearn(
        address _strategy,
        address _token,
        uint256 parts
    ) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        // This contract should never have value in it, but just incase since this is a public call
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            address _want = IStrategy(_strategy).want();
            uint256[] memory _distribution;
            uint256 _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit)
                .getExpectedReturn(_token, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(
                _token,
                _want,
                _amount,
                _expected,
                _distribution,
                0
            );
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint256 _treasury = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_treasury));
                IERC20(_want).safeTransfer(treasury, _treasury);
            }
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == globes[_token], "!globe");
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    // Function to swap between globes
    function swapExactGlobeForGlobe(
        address _fromGlobe, // From which Globe
        address _toGlobe, // To which Globe
        uint256 _fromGlobeAmount, // How much globe tokens to swap
        uint256 _toGlobeMinAmount, // How much globe tokens you'd like at a minimum
        address payable[] calldata _targets,
        bytes[] calldata _data
    ) external returns (uint256) {
        require(_targets.length == _data.length, "!length");

        // Only return last response
        for (uint256 i = 0; i < _targets.length; i++) {
            require(_targets[i] != address(0), "!converter");
            require(approvedGlobeConverters[_targets[i]], "!converter");
        }

        address _fromGlobeToken = IGlobe(_fromGlobe).token();
        address _toGlobeToken = IGlobe(_toGlobe).token();

        // Get pTokens from msg.sender
        IERC20(_fromGlobe).safeTransferFrom(
            msg.sender,
            address(this),
            _fromGlobeAmount
        );

        // Calculate how much underlying
        // is the amount of pTokens worth
        uint256 _fromGlobeUnderlyingAmount = _fromGlobeAmount
            .mul(IGlobe(_fromGlobe).getRatio())
            .div(10**uint256(IGlobe(_fromGlobe).decimals()));

        // Call 'withdrawForSwap' on Globe's current strategy if Globe
        // doesn't have enough initial capital.
        // This has moves the funds from the strategy to the Globe's
        // 'earnable' amount. Enabling 'free' withdrawals
        uint256 _fromGlobeAvailUnderlying = IERC20(_fromGlobeToken).balanceOf(
            _fromGlobe
        );
        if (_fromGlobeAvailUnderlying < _fromGlobeUnderlyingAmount) {
            IStrategy(strategies[_fromGlobeToken]).withdrawForSwap(
                _fromGlobeUnderlyingAmount.sub(_fromGlobeAvailUnderlying)
            );
        }

        // Withdraw from Globe
        // Note: this is free since its still within the "earnable" amount
        //       as we transferred the access
        IERC20(_fromGlobe).safeApprove(_fromGlobe, 0);
        IERC20(_fromGlobe).safeApprove(_fromGlobe, _fromGlobeAmount);
        IGlobe(_fromGlobe).withdraw(_fromGlobeAmount);

        // Calculate fee
        uint256 _fromUnderlyingBalance = IERC20(_fromGlobeToken).balanceOf(
            address(this)
        );
        uint256 _convenienceFee = _fromUnderlyingBalance.mul(convenienceFee).div(
            convenienceFeeMax
        );

        if (_convenienceFee > 1) {
            IERC20(_fromGlobeToken).safeTransfer(devfund, _convenienceFee.div(2));
            IERC20(_fromGlobeToken).safeTransfer(treasury, _convenienceFee.div(2));
        }

        // Executes sequence of logic
        for (uint256 i = 0; i < _targets.length; i++) {
            _execute(_targets[i], _data[i]);
        }

        // Deposit into new Globe
        uint256 _toBal = IERC20(_toGlobeToken).balanceOf(address(this));
        IERC20(_toGlobeToken).safeApprove(_toGlobe, 0);
        IERC20(_toGlobeToken).safeApprove(_toGlobe, _toBal);
        IGlobe(_toGlobe).deposit(_toBal);

        // Send Globe Tokens to user
        uint256 _toGlobeBal = IGlobe(_toGlobe).balanceOf(address(this));
        if (_toGlobeBal < _toGlobeMinAmount) {
            revert("!min-globe-amount");
        }

        IGlobe(_toGlobe).transfer(msg.sender, _toGlobeBal);

        return _toGlobeBal;
    }

    function _execute(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }
}
