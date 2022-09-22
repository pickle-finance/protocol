// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaBusdBnbLp is StrategyCronaFarmBase {
    uint256 public busd_bnb_poolId = 12;

    // Token addresses
    address public busd_bnb_lp = 0xe8B18116040acf83D6e1f873375adF61103AB45c;
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
            busd,
            bnb,
            busd_bnb_poolId,
            busd_bnb_lp,
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
        return "StrategyCronaBusdBnbLp";
    }
}
