// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeUsdcEUsdc is StrategyJoeRushFarmBase {

    uint256 public usdce_usdc_poolId = 29;

    address public joe_usdce_usdc_lp = 0x2A8A315e82F85D1f0658C5D66A452Bbdd9356783;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            usdce_usdc_poolId,
            joe_usdce_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _swapFromJoeToUsdc(uint256 _keep) internal {
        address[] memory path = new address[](4);
        path[0] = joe;
        path[1] = wavax;
        path[2] = usdce;
        path[3] = usdc;
        IERC20(joe).safeApprove(joeRouter, 0);
        IERC20(joe).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            _swapTraderJoe(joe, usdce, _joe.div(2));
            _swapFromJoeToUsdc(_joe.div(2));
        }

        // Adds in liquidity for USDCE.e/USDC
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_usdc > 0 && _joe > 0) {
            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc);

            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IJoeRouter(joeRouter).addLiquidity(
                usdc,
                usdce,
                _usdc,
                _usdce,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _usdce = IERC20(usdce).balanceOf(address(this));
            _usdc = IERC20(usdc).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_usdce > 0){
                IERC20(usdce).transfer(
                    IController(controller).treasury(),
                    _usdce
                );
            }
            if (_usdc > 0){
                IERC20(usdc).safeTransfer(
                    IController(controller).treasury(),
                    _usdc
                );
            }
            if (_joe > 0){
                IERC20(joe).safeTransfer(
                    IController(controller).treasury(),
                    _joe
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdcEUsdc";
    }
}
