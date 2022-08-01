// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {GaugeV2, Initializable, ProtocolGovernance, VirtualGaugeV2} from "./gauge-proxy-v2.sol";

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
        require(msg.sender == governance, "can only be called by governance");
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
                new GaugeV2(
                    _token,
                    _governance,
                    msg.sender,
                    _rewardSymbols,
                    _rewardTokens
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
        require(msg.sender == governance, "can only be called by governance");
        gaugeProxy = _newgaugeProxy;
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
                    msg.sender,
                    _rewardSymbols,
                    _rewardTokens
                )
            );
    }
}
