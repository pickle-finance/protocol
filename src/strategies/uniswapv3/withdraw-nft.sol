pragma solidity ^0.6.7;

import "../../interfaces/univ3/IUniswapV3PositionsNFT.sol";

contract WithdrawNFT {
    function withdraw() external {
        address CIPIO = 0x000000000088E0120F9E6652CC058AeC07564F69;
        uint256 nftId = 315352;
        IUniswapV3PositionsNFT nftManager = IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

        IERC721(address(nftManager)).safeTransferFrom(address(this), CIPIO, nftId);
    }
}
