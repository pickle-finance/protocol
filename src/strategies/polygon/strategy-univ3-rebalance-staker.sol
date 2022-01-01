// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";
import "../../polygon/lib/univ3/PoolActions.sol";
import "../../interfaces/uniswapv2.sol";
import "../../polygon/interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../../polygon/interfaces/univ3/IUniswapV3Pool.sol";
import "../../polygon/interfaces//univ3/IUniswapV3Staker.sol";
import "../../polygon/interfaces/univ3/ISwapRouter.sol";
import "../../interfaces/controllerv2.sol";

abstract contract StrategyRebalanceStakerUniV3 {
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
    address public constant univ3Router =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // Tokens
    IUniswapV3Pool public pool;

    IERC20 public token0;
    IERC20 public token1;
    uint256 private tokenId;

    int24 public tick_lower;
    int24 public tick_upper;
    int24 private tickSpacing;
    int24 private tickRangeMultiplier;
    int24 private maxDeviation = 500;
    uint24 private twapTime = 10;

    address public rewardToken;
    IUniswapV3PositionsNFT public nftManager =
        IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    mapping(address => bool) public harvesters;

    IUniswapV3Staker.IncentiveKey key;

    event InitialDeposited(uint256 tokenId);
    event Harvested(uint256 tokenId);
    event Deposited(
        uint256 tokenId,
        uint256 token0Balance,
        uint256 token1Balance
    );
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

        token0.safeApprove(address(nftManager), uint256(-1));
        token1.safeApprove(address(nftManager), uint256(-1));
        nftManager.setApprovalForAll(univ3_staker, true);
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(
            harvesters[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }

    modifier checkDeviation() {
        determineTicks();
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
        (, , , , , , , uint128 _liquidity, , , , ) = nftManager.positions(
            tokenId
        );
        return _liquidity;
    }

    function liquidityOf() public view returns (uint256) {
        return liquidityOfThis().add(liquidityOfPool());
    }

    function getName() external pure virtual returns (string memory);

    function isStakingActive() public view returns (bool stakingActive) {
        return
            (block.timestamp >= key.startTime && block.timestamp < key.endTime)
                ? true
                : false;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(
            msg.sender == governance ||
                msg.sender == strategist ||
                harvesters[msg.sender],
            "not authorized"
        );

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "not authorized"
        );

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee)
        external
    {
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

    function setIncentive(
        address _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        address _refundee
    ) public onlyBenevolent {
        rewardToken = _rewardToken;
        key = IUniswapV3Staker.IncentiveKey({
            rewardToken: IERC20Minimal(rewardToken),
            pool: IUniswapV3Pool(pool),
            startTime: _startTime,
            endTime: _endTime,
            refundee: _refundee
        });
    }

    function amountsForLiquid() public view returns (uint256, uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(
            1e18,
            tick_lower,
            tick_upper
        );
        return (a1, a2);
    }

    function determineTicks() public view returns (int24, int24) {
        (, int24 _currentTick, , , , , ) = pool.slot0();
        uint32[] memory _observeTime = new uint32[](2);
        _observeTime[0] = twapTime;
        _observeTime[1] = 0;
        (int56[] memory _cumulativeTicks, ) = pool.observe(_observeTime);
        int24 _averageTick = int24(
            (_cumulativeTicks[1] - _cumulativeTicks[0]) / twapTime
        );
        int24 _deviation = _currentTick > _averageTick
            ? _currentTick - _averageTick
            : _averageTick - _currentTick;
        require(_deviation <= maxDeviation, "Flash Loan Protection");
        int24 baseThreshold = tickSpacing * tickRangeMultiplier;
        return
            PoolVariables.baseTicks(_currentTick, baseThreshold, tickSpacing);
    }

    // **** State mutations **** //

    function deposit() public {
        // If NFT is held by staker, then withdraw
        if (nftManager.ownerOf(tokenId) != address(this) && isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(
                tokenId,
                address(this),
                bytes("")
            );
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

    function _withdrawSome(uint256 _liquidity)
        internal
        returns (uint256, uint256)
    {
        if (_liquidity == 0) return (0, 0);
        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(
                tokenId,
                address(this),
                bytes("")
            );
        }

        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(
            uint128(_liquidity),
            tick_lower,
            tick_upper
        );
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
    function withdraw(uint256 _liquidity)
        external
        returns (uint256 a0, uint256 a1)
    {
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

    function harvest() public onlyBenevolent checkDeviation {
        uint256 _initToken0 = token0.balanceOf(address(this));
        uint256 _initToken1 = token1.balanceOf(address(this));

        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).claimReward(
                IERC20Minimal(rewardToken),
                address(this),
                0
            );
            IUniswapV3Staker(univ3_staker).withdrawToken(
                tokenId,
                address(this),
                bytes("")
            );
        }

        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        nftManager.sweepToken(address(token0), 0, address(this));
        nftManager.sweepToken(address(token1), 0, address(this));

        _distributePerformanceFees(
            token0.balanceOf(address(this)).sub(_initToken0),
            token1.balanceOf(address(this)).sub(_initToken1)
        );

        _balanceProportion(tick_lower, tick_upper);

        deposit();

        redeposit();

        emit Harvested(tokenId);
    }

    //This assumes rewardToken == token0
    function getHarvestable() public view returns (uint256, uint256) {
        //This will only update when someone mint/burn/pokes the pool.
        (, , , , , , , , , , uint128 _owed0, uint128 _owed1) = nftManager
        .positions(tokenId);

        uint256 _stakingRewards;
        if (isStakingActive()) {
            _stakingRewards = IUniswapV3Staker(univ3_staker).rewards(
                key.rewardToken,
                address(this)
            );
        }
        if (address(key.rewardToken) == address(token0)) {
            _owed0 = _owed0 + uint128(_stakingRewards);
        } else if (address(key.rewardToken) == address(token1)) {
            _owed1 = _owed1 + uint128(_stakingRewards);
        }
        return (uint256(_owed0), uint256(_owed1));
    }

    //Need to call this at end of Liquidity Mining This assumes rewardToken is token0 or token1
    function endOfLM() external onlyBenevolent {
        require(block.timestamp > key.endTime, "Not End of LM");

        uint256 _liqAmt0 = token0.balanceOf(address(this));
        uint256 _liqAmt1 = token1.balanceOf(address(this));
        // claim entire rewards
        IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
        IUniswapV3Staker(univ3_staker).claimReward(
            IERC20Minimal(rewardToken),
            address(this),
            0
        );
        IUniswapV3Staker(univ3_staker).withdrawToken(
            tokenId,
            address(this),
            bytes("")
        );

        _distributePerformanceFees(
            token0.balanceOf(address(this)).sub(_liqAmt0),
            token1.balanceOf(address(this)).sub(_liqAmt1)
        );
    }

    //This assumes rewardToken == (token0 || token1)
    function rebalance()
        external
        onlyBenevolent
        checkDeviation
        returns (uint256 _tokenId)
    {
        if (tokenId != 0) {
            uint256 _initToken0 = token0.balanceOf(address(this));
            uint256 _initToken1 = token1.balanceOf(address(this));

            if (isStakingActive()) {
                // If NFT is held by staker, then withdraw
                IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);

                // claim entire rewards
                IUniswapV3Staker(univ3_staker).claimReward(
                    IERC20Minimal(rewardToken),
                    address(this),
                    0
                );
                IUniswapV3Staker(univ3_staker).withdrawToken(
                    tokenId,
                    address(this),
                    bytes("")
                );
            }
            (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(
                tokenId
            );
            (uint256 _liqAmt0, uint256 _liqAmt1) = nftManager.decreaseLiquidity(
                IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: uint128(_liquidity),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 300
                })
            );

            // This has to be done after DecreaseLiquidity to collect the tokens we
            // decreased and the fees at the same time.
            nftManager.collect(
                IUniswapV3PositionsNFT.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );

            nftManager.sweepToken(address(token0), 0, address(this));
            nftManager.sweepToken(address(token1), 0, address(this));
            nftManager.burn(tokenId);

            _distributePerformanceFees(
                token0.balanceOf(address(this)).sub(_liqAmt0).sub(_initToken0),
                token1.balanceOf(address(this)).sub(_liqAmt1).sub(_initToken1)
            );
        }
        (int24 _tickLower, int24 _tickUpper) = determineTicks();
        _balanceProportion(_tickLower, _tickUpper);
        //Need to do this again after the swap to cover any slippage.
        uint256 _amount0Desired = token0.balanceOf(address(this));
        uint256 _amount1Desired = token1.balanceOf(address(this));

        (_tokenId, , , ) = nftManager.mint(
            IUniswapV3PositionsNFT.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: _tickLower,
                tickUpper: _tickUpper,
                amount0Desired: _amount0Desired,
                amount1Desired: _amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            })
        );

        //Record updated information.
        tokenId = _tokenId;
        tick_lower = _tickLower;
        tick_upper = _tickUpper;

        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }

        if (tokenId == 0) {
            emit InitialDeposited(_tokenId);
        }

        emit Rebalanced(tokenId, _tickLower, _tickUpper);
    }

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
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

    function _distributePerformanceFees(uint256 _amount0, uint256 _amount1)
        internal
    {
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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _balanceProportion(int24 _tickLower, int24 _tickUpper) internal {
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
        (_cache.amount0, _cache.amount1) = pool.amountsForLiquidity(
            _cache.liquidity,
            _tickLower,
            _tickUpper
        );

        //Determine Trade Direction
        bool _zeroForOne;
        if (_cache.amount1Desired == 0) {
            _zeroForOne = true;
        } else {
            _zeroForOne = PoolVariables.amountsDirection(
                _cache.amount0Desired,
                _cache.amount1Desired,
                _cache.amount0,
                _cache.amount1
            );
        }

        //Determine Amount to swap
        uint256 _amountSpecified = _zeroForOne
            ? (_cache.amount0Desired.sub(_cache.amount0).div(2))
            : (_cache.amount1Desired.sub(_cache.amount1).div(2));

        if (_amountSpecified > 0) {
            //Determine Token to swap
            address _inputToken = _zeroForOne
                ? address(token0)
                : address(token1);

            IERC20(_inputToken).safeApprove(univ3Router, 0);
            IERC20(_inputToken).safeApprove(univ3Router, _amountSpecified);

            //Swap the token imbalanced
            ISwapRouter(univ3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _inputToken,
                    tokenOut: _zeroForOne ? address(token1) : address(token0),
                    fee: pool.fee(),
                    recipient: address(this),
                    amountIn: _amountSpecified,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
}
