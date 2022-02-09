// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/looks-chef.sol";

contract StrategyLooksEthLp is StrategyBase {
    // Token addresses
    address public constant looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
    address public constant looksChef =
        0x2A70e7F51f6cd40C3E9956aa964137668cBfAdC5;
    address public uni_looks_eth_lp =
        0xDC00bA87Cc2D99468f7f34BC04CBf72E111A32f7;

    // How much LOOKS tokens to keep?
    uint256 public keepLOOKS = 2000;
    uint256 public constant keepLOOKSMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            uni_looks_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ILookschef(looksChef).userInfo(address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ILookschef(looksChef).calculatePendingRewards(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(looksChef, 0);
            IERC20(want).safeApprove(looksChef, _want);
            ILookschef(looksChef).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILookschef(looksChef).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    function setKeepLOOKS(uint256 _keepLOOKS) external {
        require(msg.sender == timelock, "!timelock");
        keepLOOKS = _keepLOOKS;
    }

    function harvest() public override onlyBenevolent {
        // Collects LOOKS tokens
        ILookschef(looksChef).harvest();
        uint256 _looks = IERC20(looks).balanceOf(address(this));

        // Swap half to WETH
        if (_looks > 0) {
            uint256 _keepLOOKS = _looks.mul(keepLOOKS).div(keepLOOKSMax);

            IERC20(looks).safeTransfer(
                IController(controller).treasury(),
                _keepLOOKS
            );
            _looks = IERC20(looks).balanceOf(address(this));

            IERC20(looks).safeApprove(univ2Router2, 0);
            IERC20(looks).safeApprove(univ2Router2, _looks.div(2));
            _swapUniswap(looks, weth, _looks.div(2));
        }

        // Adds in liquidity for ETH/LOOKS
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        _looks = IERC20(looks).balanceOf(address(this));
        if (_weth > 0 && _looks > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            IERC20(looks).safeApprove(univ2Router2, 0);
            IERC20(looks).safeApprove(univ2Router2, _looks);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                looks,
                _weth,
                _looks,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(looks).safeTransfer(
                IController(controller).treasury(),
                IERC20(looks).balanceOf(address(this))
            );
        }

        // We want to get back LOOKS LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLooksEthLp";
    }
}
