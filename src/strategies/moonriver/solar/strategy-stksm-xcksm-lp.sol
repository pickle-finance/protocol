// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base-v3.sol";
import "../../../interfaces/weth.sol";

interface SwapFlashLoan {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external;
}

contract StrategyStksmXcksmLp is StrategySolarFarmBaseV3 {
    address public constant _lp = 0x493147C85Fe43F7B056087a6023dF32980Bcb2D1;

    uint256 public constant _poolId = 13;

    address public constant pool = 0x77D4b212770A7cA26ee70b1E0f27fC36da191c53;

    address public constant ldo = 0x6Ccf12B480A99C54b23647c995f4525D544A7E72;
    address public constant xcksm = 0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySolarFarmBaseV3(_poolId, _lp, _governance, _strategist, _controller, _timelock) {
        swapRoutes[ldo] = [ldo, movr];
        swapRoutes[solar] = [solar, movr];
        swapRoutes[xcksm] = [movr, xcksm];

        IERC20(_lp).approve(solarChef, uint256(-1));
        IERC20(xcksm).approve(pool, uint256(-1));
        IERC20(ldo).approve(sushiRouter, uint256(-1));
        IERC20(solar).approve(sushiRouter, uint256(-1));
        IERC20(movr).approve(sushiRouter, uint256(-1));
    }

    function harvest() public override {
        ISolarChef(solarChef).deposit(poolId, 0);

        uint256 _ldo = IERC20(ldo).balanceOf(address(this));
        uint256 _solar = IERC20(solar).balanceOf(address(this));
        if (_ldo > 0 && swapRoutes[ldo].length > 1) _swapSushiswapWithPath(swapRoutes[ldo], _ldo);
        if (_solar > 0 && swapRoutes[solar].length > 1) _swapSushiswapWithPath(swapRoutes[solar], _solar);

        // Wrap naked MOVR to WMOVR
        uint256 _native = address(this).balance;
        if (_native > 0) WETH(movr).deposit{value: _native}();

        uint256 _movr = IERC20(movr).balanceOf(address(this));
        if (_movr == 0) return;

        uint256 _keepReward = _movr.mul(keepReward).div(keepRewardMax);

        IERC20(movr).safeTransfer(IController(controller).treasury(), _keepReward);

        _movr = _movr.sub(_keepReward);

        _swapSushiswapWithPath(swapRoutes[xcksm], _movr);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = IERC20(xcksm).balanceOf(address(this));

        SwapFlashLoan(pool).addLiquidity(amounts, 0, block.timestamp.add(300));

        deposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStksmXcksmLp";
    }
}
