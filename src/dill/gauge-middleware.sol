// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GaugeV2, Initializable, ProtocolGovernance, VirtualGaugeV2, RootChainGaugeV2} from "./gauge-proxy-v2.sol";

contract GaugeMiddleware is ProtocolGovernance, Initializable {
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
        address _governance
    ) external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        require(_token != address(0), "address of token cannot be zero");
        return
            address(
                new GaugeV2(
                    _token,
                    _governance
                )
            );
    }
}

contract VirtualGaugeMiddleware is ProtocolGovernance, Initializable {
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

    function addVirtualGauge(
        address _jar,
        address _governance
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
                    _governance
                )
            );
    }
}

contract RootChainGaugeMiddleware is ProtocolGovernance, Initializable {
    address public gaugeProxy;
    address public anyswap;

    function initialize(
        address _gaugeProxy,
        address _governance,
        address _anyswap
    ) public initializer {
        require(
            _gaugeProxy != address(0),
            "_gaugeProxy address cannot be set to zero"
        );
        require(
            _governance != _gaugeProxy,
            "_governance address and _gaugeProxy cannot be same"
        );
        gaugeProxy = _gaugeProxy;
        governance = _governance;
        anyswap = _anyswap;
    }

    function changeGaugeProxy(address _newgaugeProxy) external {
        require(msg.sender == governance, "can only be called by gaugeProxy");
        gaugeProxy = _newgaugeProxy;
    }

    function addRootChainGauge() external returns (address) {
        require(msg.sender == gaugeProxy, "can only be called by gaugeProxy");
        return address(new RootChainGaugeV2(anyswap));
    }
}
