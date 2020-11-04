pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

contract Proxy {
    constructor() public {}

    receive() external payable {}

    fallback() external payable {}

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(_target != address(0), "!proxy");

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

    function executes(address[] memory targets, bytes[] memory data)
        public
        payable
        returns (bytes memory response)
    {
        bytes memory resp;

        for (uint256 i = 0; i < targets.length; i++) {
            resp = execute(targets[i], data[i]);
        }

        return resp;
    }
}
