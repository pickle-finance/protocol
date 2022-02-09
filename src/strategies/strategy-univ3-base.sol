// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";

import "../interfaces/jarv2.sol";
import "../interfaces/staking-rewards.sol";
import "../interfaces/uniswapv2.sol";
import "../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/univ3/IUniswapV3Pool.sol";
import "../interfaces/univ3/ISwapRouter.sol";
import "../interfaces/controllerv2.sol";
import "../lib/univ3/PoolActions.sol";

// Strategy Contract Basics

abstract contract StrategyUniV3Base {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using PoolVariables for IUniswapV3Pool;

    // Perfomance fees - start with 20%
    uint256 public performanceTreasuryFee = 2000;
    uint256 public constant performanceTreasuryMax = 10000;

    // Tokens
    IUniswapV3Pool public pool;

    IERC20 public token0;
    IERC20 public token1;

    int24 public tick_lower;
    int24 public tick_upper;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV3PositionsNFT public nftManager = IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address public constant univ3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant univ3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    // Dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    mapping(address => bool) public harvesters;

    constructor(
        address _pool,
        int24 _tick_lower,
        int24 _tick_upper,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        require(_pool != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        pool = IUniswapV3Pool(_pool);
        tick_lower = _tick_lower;
        tick_upper = _tick_upper;

        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());

        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == governance || msg.sender == strategist);
        _;
    }

    // **** Views **** //

    function liquidityOfThis() public view returns (uint256) {
        uint256 liquidity = uint256(
            pool.liquidityForAmounts(
                token0.balanceOf(address(this)),
                token1.balanceOf(address(this)),
                tick_lower,
                tick_upper
            )
        );
        return liquidity;
    }

    function liquidityOfPool() public view virtual returns (uint256);

    function liquidityOf() public view returns (uint256) {
        return liquidityOfThis().add(liquidityOfPool());
    }

    function getName() external pure virtual returns (string memory);

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance || msg.sender == strategist || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance || msg.sender == strategist, "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        performanceTreasuryFee = _performanceTreasuryFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function getProportion() public view returns (uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(1e18, tick_lower, tick_upper);
        return (a2 * (10**18)) / a1;
    }

    function _wrapAllToNFT() internal returns (uint256, uint256) {
        (uint256 _tokenId, uint256 _liquidity) = _wrapSomeToNFT(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
        return (_tokenId, _liquidity);
    }

    function _wrapSomeToNFT(uint256 _amount0, uint256 _amount1) internal returns (uint256, uint256) {
        token0.safeApprove(address(nftManager), 0);
        token0.safeApprove(address(nftManager), _amount0);

        token1.safeApprove(address(nftManager), 0);
        token1.safeApprove(address(nftManager), _amount1);

        (uint256 _tokenId, uint128 _liquidity, , ) = nftManager.mint(
            IUniswapV3PositionsNFT.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: tick_lower,
                tickUpper: tick_upper,
                amount0Desired: _amount0,
                amount1Desired: _amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            })
        );
        nftManager.refundETH();
        return (_tokenId, uint256(_liquidity));
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _liquidity) external returns (uint256 a0, uint256 a1) {
        require(msg.sender == controller, "!controller");
        (a0, a1) = _withdrawSome(_liquidity);

        address _jar = IControllerV2(controller).jars(address(pool));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        token0.safeTransfer(_jar, a0);
        token1.safeTransfer(_jar, a1);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 a0, uint256 a1) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        address _jar = IControllerV2(controller).jars(address(pool));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        a0 = token0.balanceOf(address(this));
        a1 = token1.balanceOf(address(this));
        token0.safeTransfer(_jar, a0);
        token1.safeTransfer(_jar, a1);
    }

    function _withdrawAll() internal returns (uint256 a0, uint256 a1) {
        (a0, a1) = _withdrawSome(liquidityOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256, uint256);

    function harvest() public virtual;

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data) public payable returns (bytes memory response) {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _swapUniswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token0.balanceOf(address(this));
        if (_balance0 > 0) {
            // Treasury fees
            token0.safeTransfer(
                IControllerV2(controller).treasury(),
                _balance0.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );
        }

        if (_balance1 > 0) {
            // Treasury fees
            token1.safeTransfer(
                IControllerV2(controller).treasury(),
                _balance1.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );
        }
        deposit();

        // Donates DUST
        token0.safeTransfer(IControllerV2(controller).treasury(), token0.balanceOf(address(this)));
        token1.safeTransfer(IControllerV2(controller).treasury(), token1.balanceOf(address(this)));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
