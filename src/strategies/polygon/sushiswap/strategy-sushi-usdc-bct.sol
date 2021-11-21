// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiUsdcBctLp is StrategySushiFarmBase {
    // Usdc/Bct pool id in MasterChef contract
    uint256 public sushi_usdc_bct_poolId = 37;

    //Token addresses
    address public usdc_bct_lp = 0x1E67124681b402064CD0ABE8ed1B5c79D2e02f64;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public bct = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            usdc,
            bct,
            sushi_usdc_bct_poolId,
            usdc_bct_slp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // ***** Views *****

    function getName() external pure override returns (string memory) {
        return "StrategySushiUsdcBctLp";
    }

    // ***** State Mutations *****

    function harvest() public override onlyBenevolent {
        // Collects SUSHI tokens
        IMiniChefV2(miniChef).harvest(poolId, address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            _swapSushiswap(sushi, weth, _sushi);
        }

        // Collect MATIC tokens
        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            _swapSushiswap(wmatic, weth, _wmatic);
        }

        // Swap half WETH for usdc
        uint256 _weth = IERC20(weth).balanceOf(address(this));
            address[] memory pathUsdc = new address[](3);
            pathUsdc[0] = weth;
            pathUsdc[1] = bct;
            pathUsdc[2] = usdc;
            _swapSushiswapWithPath(pathUsdc, _weth.div(2));
        }

        // Swap half WETH for bct
        if (_weth > 0) {
          address[] memory pathBct = new address[](2);
          pathBct[0] = weth;
          pathBct[1] = bct;
          _swapSushiswapWithPath(pathBct, _weth.div(2));
        }

        // Adds in liquidity for token0/token1
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        uint256 _bct = IERC20(bct).balanceOf(address(this));
        if (_usdc > 0 && _bct > 0) {
          IERC20(usdc).safeApprove(sushiRouter, 0);
          IERC20(usdc).safeApprove(sushiRouter, _usdc);
          IERC20(bct).safeApprove(sushiRouter, 0);
          IERC20(bct).safeApprove(sushiRouter, _bct);

          UniswapRouterV2(sushiRouter).addLiquidity(
            usdc,
            bct,
            _usdc,
            _bct,
            0,
            0,
            address(this),
            now + 60
          );

          //Donates DUST
          IERC20(usdc).transfer(
            IController(controller).treasury(),
            IERC20(usdc).balanceOf(address(this))
          );
          IERC20(bct).safeTransfer(
            IController(controller).treasury(),
            IERC20(bct).balanceOf(address(this))
          );
        }

        // We want to get back SUSHI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
