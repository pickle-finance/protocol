// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;


interface ERC20 {
 function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Proxy {
    function transferFrom(address contractAddr, address from, address to, uint256 tokenId) external {
        ERC20(contractAddr).transferFrom(from, to,  tokenId );
    }

    function proxyExecute(address contractAddr, bytes memory data) external {
        (bool success, ) = contractAddr.call(data);
        require(success,"proxyExecute Failed!");
    }
}
