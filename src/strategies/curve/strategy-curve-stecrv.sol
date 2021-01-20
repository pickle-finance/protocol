// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/steth.sol";
import "../../interfaces/weth.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-base.sol";

interface ICurveFi {
    function add_liquidity(
        // stETH pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function balances(int128) external view returns (uint256);
}

contract StrategyCurveSteCRV is StrategyBase {
    // Curve
    IStEth public stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // lido stEth
    IERC20 public steCRV = IERC20(0x06325440D014e39736583c165C2963BA99fAf14E); // ETH-stETH curve lp

    // curve dao
    ICurveGauge public gauge = ICurveGauge(0x182B723a58739a9c974cFDB385ceaDb237453c28); // stEthGauge
    ICurveFi public curve = ICurveFi(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022); // stEthSwap
    address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // tokens we're farming
    IERC20 public constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant ldo = IERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(address(steCRV), _governance, _strategist, _controller, _timelock)
    {
        steCRV.approve(address(gauge), uint256(-1));
        stEth.approve(address(curve), uint256(-1));
        ldo.safeApprove(address(univ2Router2), uint256(-1));
        crv.approve(address(univ2Router2), uint256(-1));
    }

    // swap for eth
    receive() external payable {}

    // **** Getters ****

    function balanceOfPool() public override view returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurveStETH";
    }

    function getHarvestable() external view returns (uint256) {
        return gauge.claimable_reward(address(this), address(crv));
    }

    function getHarvestableEth() external view returns (uint256) {
        uint256 claimableLdo = gauge.claimable_reward(address(this), address(ldo));
        uint256 claimableCrv = gauge.claimable_reward(address(this), address(crv));

        return _estimateSell(address(crv), claimableCrv).add(_estimateSell(address(ldo), claimableLdo));
    }

    function _estimateSell(address currency, uint256 amount) internal view returns (uint256 outAmount){
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = weth;
        uint256[] memory amounts = UniswapRouterV2(univ2Router2).getAmountsOut(amount, path);
        outAmount = amounts[amounts.length - 1];

        return outAmount;
    }

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutations ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            gauge.deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        gauge.withdraw(_amount);
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun / sandwiched
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned/sandwiched?
        //      if so, a new strategy will be deployed.

        gauge.claim_rewards();
        ICurveMintr(mintr).mint(address(gauge));

        uint256 _ldo = ldo.balanceOf(address(this));
        uint256 _crv = crv.balanceOf(address(this));

        if (_crv > 0) {
            // How much CRV to keep to restake?
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            // IERC20(crv).safeTransfer(address(crvLocker), _keepCRV);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }

            // How much CRV to swap?
            _crv = _crv.sub(_keepCRV);
            _swapUniswap(address(crv), weth, _crv);
        }
        if (_ldo > 0) {
            _swapUniswap(address(ldo), weth, _ldo);
        }
        WETH(weth).withdraw(WETH(weth).balanceOf(address(this)));

        uint256 _eth = address(this).balance;
        stEth.submit{value: _eth/2}(strategist);
        _eth = address(this).balance;
        uint256 _stEth = stEth.balanceOf(address(this));

        uint256[2] memory liquidity;
        liquidity[0] = _eth;
        liquidity[1] = _stEth;

        curve.add_liquidity{value: _eth}(liquidity, 0);

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }
}
