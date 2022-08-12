// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
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

abstract contract AnyCallApp {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor(address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

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
        // (address callFrom, ,) = IExecutor(
        //     IAnycallV6Proxy(anyCallProxy).executor()
        // ).context();
        return _anyExecute(data);
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
