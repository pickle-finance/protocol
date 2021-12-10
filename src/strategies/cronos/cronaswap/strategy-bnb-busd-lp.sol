// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaBnbBusdLp is StrategyCronaFarmBase {
    uint256 public bnb_busd_poolId = 6;

    // Token addresses
    address public bnb_busd_lp = 0xe8B18116040acf83D6e1f873375adF61103AB45c;
    address public busd = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;
    address public bnb = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            bnb,
            busd,
            bnb_busd_poolId,
            bnb_busd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[busd] = [crona, usdc, busd];
        uniswapRoutes[bnb] = [crona, usdc, busd, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaBnbBusdLp";
    }
}
