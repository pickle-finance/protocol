pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {VirtualGauge, Gauge, ProtocolGovernance} from "./gauge-proxy-v2.sol";

contract GaugeMiddleware is Initializable {
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

    function addGauge(address _token) external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        require(_token != address(0), "address of token cannot be zero");
        return address(new Gauge(_token));
    }

    function addVirtualGauge(
        address _token,
        address _jar,
        address _governance
    ) external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        require(_token != address(0), "address of token cannot be zero");
        require(_jar != address(0), "address of jar cannot be zero");
        require(
            _governance != address(0),
            "address of governance cannot be zero"
        );
        return address(new VirtualGauge(_token, _jar, _governance));
    }
}
