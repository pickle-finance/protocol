// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
import {SideChainGauge} from "./side-chain-gauge.sol";

interface IAnycallV6Proxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (address);
}

interface IExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

interface IGauge {
    function notifyRewardAmount() external;
}

abstract contract AnyCallApp {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;
    address public mainChainAnySwapBridger;

    mapping(address => address) public receiveGauge;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor(
        address anyCallProxy_,
        address _mainChainAnySwapBridger,
        uint256 flag_
    ) {
        anyCallProxy = anyCallProxy_;
        mainChainAnySwapBridger = _mainChainAnySwapBridger;
        flag = flag_;
    }

    function _setFlag(uint256 _flag) internal {
        require(_flag != 1, "cannot set to 1");
        require(_flag < 3, "cannot exceed 3");
        flag = _flag;
    }

    function _setReceiveGauge(address _mainChaingauge, address _token)
        internal
        virtual;

    function _anyExecute(bytes calldata data)
        internal
        virtual
        returns (bool success, bytes memory result);

    // function _anyFallback(bytes calldata data) internal virtual;

    function _anyCall(
        address _to,
        bytes memory _data,
        address _fallback,
        uint256 _toChainID
    ) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        }
    }

    function anyExecute(bytes calldata data)
        external
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (address callFrom, uint256 fromChainID, ) = IExecutor(
            IAnycallV6Proxy(anyCallProxy).executor()
        ).context();
        require(mainChainAnySwapBridger == callFrom, "Gauge is not registered");
        _anyExecute(data);
    }

    // function anyFallback(address to, bytes calldata data)
    //     external
    //     onlyExecutor
    // {
    //     (address callFrom, , ) = IExecutor(
    //         IAnycallV6Proxy(anyCallProxy).executor()
    //     ).context();
    //     require(address(this) == callFrom, "call not allowed");
    //     _anyFallback(data);
    // }
}

contract SideChainVault is AnyCallApp {
    address public governance;
    address public admin;

    constructor(
        address _anyswap,
        address _mainChainAnySwapBridger,
        uint256 _flag,
        address _governance,
        address _admin
    ) AnyCallApp(_anyswap, _mainChainAnySwapBridger, _flag) {
        governance = _governance;
        admin = _admin;
    }

    function _anyExecute(bytes calldata data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (address mainChainGauge, uint256 amount) = abi.decode(
            data,
            (address, uint256)
        );
        // TODO: mint token to gauge, yet to figure out
        address gauge = receiveGauge[mainChainGauge];
        IGauge(gauge).notifyRewardAmount();
    }

    function addGauge(address _mainChaingauge, address _token) external {
        require(msg.sender == admin, "only admin can call this function ");
        _setReceiveGauge(_mainChaingauge, _token);
    }

    function removeGauge(address _mainChaingauge) external {
        require(msg.sender == admin, "only admin can call this function ");
        delete receiveGauge[_mainChaingauge];
        emit SideChainGaugeRemoved(_mainChaingauge);
    }

    function _setReceiveGauge(address _mainChaingauge, address _token)
        internal
        override
    {
        require(
            _mainChaingauge != address(0),
            "main chain gauge cannot be zero address"
        );
        address gauge = receiveGauge[_mainChaingauge];
        require(gauge == address(0), "Already gauge is registered");
        address newSideChainGauge = address(
            new SideChainGauge(_token, governance, address(this))
        );
        receiveGauge[_mainChaingauge] = newSideChainGauge;
        emit SideChainGaugeAdded(_mainChaingauge, _token, newSideChainGauge);
    }

    event SideChainGaugeAdded(
        address indexed mainChainGauge,
        address indexed token,
        address indexed sideChainGauge
    );
    event SideChainGaugeRemoved(address indexed mainChainGauge);
}
