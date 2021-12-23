// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";
import "../lib/univ3/PoolActions.sol";
import "../interfaces/jarv2.sol";
import "../interfaces/uniswapv2.sol";
import "../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/univ3/IUniswapV3Pool.sol";
import "../interfaces//univ3/IUniswapV3Staker.sol";
import "../interfaces/univ3/ISwapRouter.sol";
import "../interfaces/controllerv2.sol";

abstract contract StrategyRebalanceUniV3 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using PoolVariables for IUniswapV3Pool;

    // Perfomance fees - start with 20%
    uint256 public performanceTreasuryFee = 2000;
    uint256 public constant performanceTreasuryMax = 10000;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    address public univ3_staker;

    // Dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant univ3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant univ3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // Tokens
    IUniswapV3Pool public pool;

    IERC20 public token0;
    IERC20 public token1;
    uint256 public tokenId;

    int24 public tick_lower;
    int24 public tick_upper;
    int24 public tickSpacing;
    int24 public tickRangeMultiplier;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public rewardToken;
    IUniswapV3PositionsNFT public nftManager = IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    mapping(address => bool) public harvesters;

    bool public stakingActive = true;
    IUniswapV3Staker.IncentiveKey key;

    event InitialDeposited(uint256 tokenId);
    event Harvested(uint256 tokenId);
    event Deposited(uint256 tokenId, uint256 token0Balance, uint256 token1Balance);
    event Withdrawn(uint256 tokenId, uint256 _liquidity);
    event Rebalanced(uint256 tokenId, int24 _tickLower, int24 _tickUpper);

    constructor(
        address _pool,
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;

        pool = IUniswapV3Pool(_pool);

        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());

        tickSpacing = pool.tickSpacing();
        tickRangeMultiplier = _tickRangeMultiplier;
        (tick_lower, tick_upper) = determineTicks();

        token0.safeApprove(address(nftManager), uint256(-1));
        token1.safeApprove(address(nftManager), uint256(-1));
        nftManager.setApprovalForAll(univ3_staker, true);
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

    function liquidityOfPool() public view returns (uint256) {
        (, , , , , , , uint128 _liquidity, , , , ) = nftManager.positions(tokenId);
        return _liquidity;
    }

    function liquidityOf() public view returns (uint256) {
        return liquidityOfThis().add(liquidityOfPool());
    }

    function getName() external pure virtual returns (string memory);

    function isStakingActive() internal returns (bool stakingActive) {
        return (block.timestamp >= key.startTime && block.timestamp < key.endTime) ? true : false;
    }

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
        return (a2 * (10**12) * (10**18)) / a1;
    }
    function amountsForLiquid() public view returns (uint256,uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(1e18, tick_lower, tick_upper);
        return (a1, a2);
    }

    function getSqrtRatioAtTick(int24 _tick) public view returns (uint160) {
        return TickMath.getSqrtRatioAtTick(_tick);
    }

    function getSqrtRatioAtRanges() public view returns (uint160, uint160) {
        (int24 _tickLower, int24 _tickUpper) = determineTicks();
        return (TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper));
    }

    function getTickAtSqrtRatio(uint160 _sqrRtRatio) public view returns (int24) {
        return TickMath.getTickAtSqrtRatio(_sqrRtRatio);
    }

    function determineTicks() public view returns (int24, int24) {
        uint32[] memory _observeTime = new uint32[](2);
        _observeTime[0] = 3600;
        _observeTime[1] = 0;
        (int56[] memory _cumulativeTicks, ) = pool.observe(_observeTime);
	int56 _averageTick = (_cumulativeTicks[1] - _cumulativeTicks[0]) / 3600;
        int24 baseThreshold = tickSpacing * tickRangeMultiplier;
        return PoolVariables.baseTicks(int24(_averageTick), baseThreshold, tickSpacing);
    }

    // **** State mutations **** //

    function depositInitial() public returns (uint256 _tokenId) {
        require(msg.sender == governance || msg.sender == strategist, "not authorized");
        require(tokenId == 0, "token already set");

        uint256 _token0 = token0.balanceOf(address(this));
        uint256 _token1 = token1.balanceOf(address(this));

        (_tokenId, , , ) = nftManager.mint(
            IUniswapV3PositionsNFT.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: tick_lower,
                tickUpper: tick_upper,
                amount0Desired: _token0,
                amount1Desired: _token1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            })
        );

        nftManager.sweepToken(address(token0), 0, address(this));
        nftManager.sweepToken(address(token1), 0, address(this));

        tokenId = _tokenId;

        // Deposit + stake in Uni v3 staker only if staking is active.
        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }

        emit InitialDeposited(tokenId);
    }

    function deposit() public {
        // If NFT is held by staker, then withdraw
        if (nftManager.ownerOf(tokenId) != address(this) && isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        uint256 _token0 = token0.balanceOf(address(this));
        uint256 _token1 = token1.balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            nftManager.increaseLiquidity(
                IUniswapV3PositionsNFT.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: _token0,
                    amount1Desired: _token1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 300
                })
            );
        }
        redeposit();

        emit Deposited(tokenId, _token0, _token1);
    }

    // Deposit + stake in Uni v3 staker
    function redeposit() internal {
        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }
    }

    function _withdrawSome(uint256 _liquidity) internal returns (uint256, uint256) {
        if (_liquidity == 0) return (0, 0);
        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(uint128(_liquidity), tick_lower, tick_upper);
        (uint256 amount0, uint256 amount1) = nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(_liquidity),
                amount0Min: _a0Expect,
                amount1Min: _a1Expect,
                deadline: block.timestamp + 300
            })
        );

        //Only collect decreasedLiquidity, not trading fees.
        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            })
        );

        return (amount0, amount1);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Override base withdraw function to redeposit
    function withdraw(uint256 _liquidity) external returns (uint256 a0, uint256 a1) {
        require(msg.sender == controller, "!controller");
        (a0, a1) = _withdrawSome(_liquidity);

        address _jar = IControllerV2(controller).jars(address(pool));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        token0.safeTransfer(_jar, a0);
        token1.safeTransfer(_jar, a1);

        redeposit();

        emit Withdrawn(tokenId, _liquidity);
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

    function _swapUniswapV3(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        IERC20(_from).safeApprove(univ3Router, 0);
        IERC20(_from).safeApprove(univ3Router, _amount);

        ISwapRouter(univ3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _from,
                tokenOut: _to,
                fee: pool.fee(),
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

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

        IERC20(_from).safeApprove(univ2Router2, 0);
        IERC20(_from).safeApprove(univ2Router2, _amount);

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _swapUniswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));
        //TODO approve _from
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

        IERC20(_from).safeApprove(sushiRouter, 0);
        IERC20(_from).safeApprove(sushiRouter, _amount);

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), now.add(60));
    }

    function _distributePerformanceFees(uint256 _amount0, uint256 _amount1) internal {
        if (_amount0 > 0) {
            IERC20(token0).safeTransfer(
                IControllerV2(controller).treasury(),
                _amount0.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );
        }
        if (_amount1 > 0) {
            IERC20(token1).safeTransfer(
                IControllerV2(controller).treasury(),
                _amount1.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );
        }
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));

        _distributePerformanceFees(_balance0, _balance1);
        deposit();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function balanceProportion(int24 _tickLower, int24 _tickUpper) internal {
        PoolVariables.Info memory _cache;

        _cache.amount0Desired = token0.balanceOf(address(this));
        _cache.amount1Desired = token1.balanceOf(address(this));

        //Get Max Liquidity for Amounts we own.
        _cache.liquidity = pool.liquidityForAmounts(
            _cache.amount0Desired,
            _cache.amount1Desired,
            _tickLower,
            _tickUpper
        );

        //Get correct amounts of each token for the liquidity we have.
        (_cache.amount0, _cache.amount1) = pool.amountsForLiquidity(_cache.liquidity, _tickLower, _tickUpper);

        //Determine Trade Direction
        bool _zeroForOne = PoolVariables.amountsDirection(
            _cache.amount0Desired,
            _cache.amount1Desired,
            _cache.amount0,
            _cache.amount1
        );

        //Determine Amount to swap
        uint256 _amountSpecified = _zeroForOne
            ? (_cache.amount0Desired.sub(_cache.amount0).div(2))
            : (_cache.amount1Desired.sub(_cache.amount1).div(2));

        if (_amountSpecified > 0) {
            //Determine Token to swap
            address _inputToken = _zeroForOne ? address(token0) : address(token1);

            IERC20(_inputToken).safeApprove(univ3Router, 0);
            IERC20(_inputToken).safeApprove(univ3Router, _amountSpecified);

            //Swap the token imbalanced
            ISwapRouter(univ3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _inputToken,
                    tokenOut: _zeroForOne ? address(token1) : address(token0),
                    fee: pool.fee(),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _amountSpecified,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
}
