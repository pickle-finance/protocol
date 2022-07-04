pragma solidity >=0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}
import {GaugeV2, ProtocolGovernance, VirtualGaugeV2} from "./gauge-proxy-v2.sol";

contract GaugeMiddleware is Initializable, ProtocolGovernance {
    address public gaugeProxy;

    function initialize(address _gaugeProxy, address _governance)
        public
        initializer
    {
        require(
            _gaugeProxy != address(0),
            "_gaugeProxy address cannot be set to zero"
        );
        require(
            _governance != address(0),
            "_governance address cannot be set to zero"
        );
        require(
            _governance != _gaugeProxy,
            "_governance address and _gaugeProxy cannot be same"
        );
        gaugeProxy = _gaugeProxy;
        governance = _governance;
    }

    function changeGaugeProxy(address _newgaugeProxy) external {
        require(msg.sender == governance, "can only be called by gaugeProxy");
        gaugeProxy = _newgaugeProxy;
    }

    function addGauge(
        address _token,
        address _governance,
        string[] memory _rewardSymbols,
        address[] memory _rewardTokens
    ) external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        require(_token != address(0), "address of token cannot be zero");
        return
            address(
                new GaugeV2(_token, _governance, _rewardSymbols, _rewardTokens)
            );
    }

    function addVirtualGauge(
        address _jar,
        address _governance,
        string[] memory _rewardSymbols,
        address[] memory _rewardTokens
    ) external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        require(_jar != address(0), "address of jar cannot be zero");
        require(
            _governance != address(0),
            "address of governance cannot be zero"
        );
        return
            address(
                new VirtualGaugeV2(
                    _jar,
                    _governance,
                    _rewardSymbols,
                    _rewardTokens
                )
            );
    }
}
