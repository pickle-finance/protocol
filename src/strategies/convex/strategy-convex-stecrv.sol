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

interface IConvexDepositor {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
}

interface IConvexRewards {
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    // primary reward balance (will be in CRV)
    function earned(address account) external view returns (uint256);
    // extra rewards array getter
    function extraRewards(uint256) external view returns (address);
    function extraRewardsLength() external view returns (uint256);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    //claim rewards
    function getReward() external returns(bool);
}

interface IConvexExtraRewards {
    function earned(address account) external view returns (uint256);
}

interface IConvexToken {
    function maxSupply() external view returns (uint256);
    function reductionPerCliff() external view returns (uint256);
    function totalCliffs() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract StrategyConvexSteCRV is StrategyBase {
    // Curve
    IStEth public stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // lido stEth
    IERC20 public steCRV = IERC20(0x06325440D014e39736583c165C2963BA99fAf14E); // ETH-stETH curve lp

    // Convex
    IConvexRewards public rewardPool = IConvexRewards(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03);
    IConvexDepositor public depositor = IConvexDepositor(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    // ETH-stETH pool
    ICurveFi public curve = ICurveFi(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    // tokens we're farming
    IERC20 public constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant ldo = IERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    IERC20 public constant cvx = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    uint256 public constant pid = 25;

    // How much CVX tokens to keep
    uint256 public keepCVX = 500;
    uint256 public keepCVXMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(address(steCRV), _governance, _strategist, _controller, _timelock)
    {
        steCRV.approve(address(depositor), uint256(-1));
        stEth.approve(address(curve), uint256(-1));
        ldo.safeApprove(address(univ2Router2), uint256(-1));
        crv.approve(address(univ2Router2), uint256(-1));
        cvx.approve(address(sushiRouter), uint256(-1));
    }

    // swap for eth
    receive() external payable {}

    // **** Getters ****

    function balanceOfPool() public override view returns (uint256) {
        return rewardPool.balanceOf(address(this));
    }

    function getName() external override pure returns (string memory) {
        return "StrategyConvexStETH";
    }

    function getHarvestable() external view returns (uint256) {
        return this.getHarvestableCrv();
    }

    function getHarvestableCrv() external view returns (uint256) {
        return rewardPool.earned(address(this));
    }

    function getHarvestableLdo() external view returns (uint256) {
        return IConvexExtraRewards(rewardPool.extraRewards(0)).earned(address(this));
    }

    function getHarvestableCvx() external view returns (uint256) {
        uint256 claimableCrv = this.getHarvestableCrv();
        IConvexToken cvxInfo = IConvexToken(address(cvx));

        // https://docs.convexfinance.com/convexfinanceintegration/cvx-minting

        uint256 cliffSize = cvxInfo.reductionPerCliff();
        uint256 cliffCount = cvxInfo.totalCliffs();
        uint256 maxSupply = cvxInfo.maxSupply();
        uint256 cvxTotalSupply = cvxInfo.totalSupply();

        uint256 currentCliff = cvxTotalSupply.div(cliffSize);

        if (currentCliff < cliffCount){
            //get remaining cliffs
            uint256 remaining = cliffCount.sub(currentCliff);

            //multiply ratio of remaining cliffs to total cliffs against amount CRV received
            uint256 cvxEarned = claimableCrv.mul(remaining).div(cliffCount);

            //double check we have not gone over the max supply
            uint256 amountTillMax = maxSupply.sub(cvxTotalSupply);
            if(cvxEarned > amountTillMax){
                cvxEarned = amountTillMax;
            }
            return cvxEarned;
        }
        return 0;
    }

    function getHarvestableEth() external view returns (uint256) {
        uint256 claimableCrv = this.getHarvestableCrv();
        uint256 claimableLdo = this.getHarvestableLdo();
        uint256 claimableCvx = this.getHarvestableCvx();

        uint256 crvEth = _estimateSell(univ2Router2, address(crv), claimableCrv);
        uint256 ldoEth = _estimateSell(univ2Router2, address(ldo), claimableLdo);
        uint256 cvxEth = _estimateSell(sushiRouter,  address(cvx), claimableCvx);

        return crvEth.add(ldoEth).add(cvxEth);
    }

    function _estimateSell(address dex, address currency, uint256 amount) internal view returns (uint256 outAmount){
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = weth;
        uint256[] memory amounts = UniswapRouterV2(dex).getAmountsOut(amount, path);
        outAmount = amounts[amounts.length - 1];

        return outAmount;
    }

    // **** Setters ****

    function setKeepCVX(uint256 _keepCVX) external {
        require(msg.sender == governance, "!governance");
        keepCVX = _keepCVX;
    }

    // **** State Mutations ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            depositor.deposit(pid, _want, true);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        rewardPool.withdrawAndUnwrap(_amount, false);
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun / sandwiched
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned/sandwiched?
        //      if so, a new strategy will be deployed.

        rewardPool.getReward();

        uint256 _ldo = ldo.balanceOf(address(this));
        uint256 _crv = crv.balanceOf(address(this));
        uint256 _cvx = cvx.balanceOf(address(this));

        if (_cvx > 0) {
            // How much CVX to keep to restake?
            uint256 _keepCVX = _cvx.mul(keepCVX).div(keepCVXMax);
            if (_keepCVX > 0) {
                IERC20(cvx).safeTransfer(
                    IController(controller).treasury(),
                    _keepCVX
                );
            }

            // How much CVX to swap?
            _cvx = _cvx.sub(_keepCVX);
            _swapSushiswap(address(cvx), weth, _cvx);
        }
        if (_ldo > 0) {
            _swapUniswap(address(ldo), weth, _ldo);
        }
        if (_crv > 0) {
            _swapUniswap(address(crv), weth, _crv);
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

        _distributePerformanceFeesAndDeposit();
    }
}
