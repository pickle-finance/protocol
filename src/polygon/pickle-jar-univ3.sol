pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
// ─██████████████─██████████─██████████████─██████──████████─██████─────────██████████████────────────██████─██████████████─████████████████───
// ─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░██─██░░██──██░░░░██─██░░██─────────██░░░░░░░░░░██────────────██░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───
// ─██░░██████░░██─████░░████─██░░██████████─██░░██──██░░████─██░░██─────────██░░██████████────────────██░░██─██░░██████░░██─██░░████████░░██───
// ─██░░██──██░░██───██░░██───██░░██─────────██░░██──██░░██───██░░██─────────██░░██────────────────────██░░██─██░░██──██░░██─██░░██────██░░██───
// ─██░░██████░░██───██░░██───██░░██─────────██░░██████░░██───██░░██─────────██░░██████████────────────██░░██─██░░██████░░██─██░░████████░░██───
// ─██░░░░░░░░░░██───██░░██───██░░██─────────██░░░░░░░░░░██───██░░██─────────██░░░░░░░░░░██────────────██░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───
// ─██░░██████████───██░░██───██░░██─────────██░░██████░░██───██░░██─────────██░░██████████────██████──██░░██─██░░██████░░██─██░░██████░░████───
// ─██░░██───────────██░░██───██░░██─────────██░░██──██░░██───██░░██─────────██░░██────────────██░░██──██░░██─██░░██──██░░██─██░░██──██░░██─────
// ─██░░██─────────████░░████─██░░██████████─██░░██──██░░████─██░░██████████─██░░██████████────██░░██████░░██─██░░██──██░░██─██░░██──██░░██████─
// ─██░░██─────────██░░░░░░██─██░░░░░░░░░░██─██░░██──██░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██────██░░░░░░░░░░██─██░░██──██░░██─██░░██──██░░░░░░██─
// ─██████─────────██████████─██████████████─██████──████████─██████████████─██████████████────██████████████─██████──██████─██████──██████████─
// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

import "../interfaces/controllerv2.sol";
import "../lib/erc20.sol";
import "./lib/univ3/PoolActions.sol";
import "../lib/reentrancy-guard.sol";
import "../lib/safe-math.sol";
import "./interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "./interfaces/univ3/IUniswapV3Pool.sol";
import "./interfaces/univ3/ISwapRouter.sol";
import "../interfaces/weth.sol";

contract PickleJarUniV3Poly is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using PoolVariables for IUniswapV3Pool;

    address public constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant univ3Router =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address public governance;
    address public timelock;
    address public controller;

    bool public paused;

    IUniswapV3Pool public pool;

    IERC20 public token0;
    IERC20 public token1;

    constructor(
        string memory _name,
        string memory _symbol,
        address _pool,
        address _governance,
        address _timelock,
        address _controller
    ) public ERC20(_name, _symbol) {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());

        governance = _governance;
        timelock = _timelock;
        controller = _controller;
        paused = false;
    }

    function totalLiquidity() public view returns (uint256) {
        return
            liquidityOfThis().add(
                IControllerV2(controller).liquidityOf(address(pool))
            );
    }

    function liquidityOfThis() public view returns (uint256) {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));
        return
            uint256(
                pool.liquidityForAmounts(
                    _balance0,
                    _balance1,
                    getLowerTick(),
                    getUpperTick()
                )
            );
    }

    function getUpperTick() public view returns (int24) {
        return IControllerV2(controller).getUpperTick(address(pool));
    }

    function getLowerTick() public view returns (int24) {
        return IControllerV2(controller).getLowerTick(address(pool));
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) public {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    event JarPaused(uint256 block, uint256 timestamp);

    function setPaused(bool _paused) external {
        require(msg.sender == governance, "!governance");
        paused = _paused;
        emit JarPaused(block.number, block.timestamp);
    }

    function earn() public {
        require(liquidityOfThis() > 0, "no liquidity here");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        token0.safeTransfer(controller, balance0);
        token1.safeTransfer(controller, balance1);

        IControllerV2(controller).earn(address(pool), balance0, balance1);
    }

    function deposit(uint256 token0Amount, uint256 token1Amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        bool _maticUsed;
        (token0Amount, token1Amount, _maticUsed) = _convertMatic(
            token0Amount,
            token1Amount
        );

        _deposit(token0Amount, token1Amount);

        uint256 _liquidity = _refundUnused(_maticUsed);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _liquidity;
        } else {
            shares = (_liquidity.mul(totalSupply())).div(
                IControllerV2(controller).liquidityOf(address(pool))
            );
        }

        _mint(msg.sender, shares);

        earn();
    }

    function getProportion() public view returns (uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(
            1e18,
            getLowerTick(),
            getUpperTick()
        );
        return (a2 * (10**18)) / a1;
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public nonReentrant whenNotPaused {
        uint256 r = (totalLiquidity().mul(_shares)).div(totalSupply());
        (uint256 _expectA0, uint256 _expectA1) = pool.amountsForLiquidity(
            uint128(r),
            getLowerTick(),
            getUpperTick()
        );
        _burn(msg.sender, _shares);
        // Check balance
        uint256[2] memory _balances = [
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        ];
        uint256 b = liquidityOfThis();

        if (b < r) {
            uint256 _withdraw = r.sub(b);
            (uint256 _a0, uint256 _a1) = IControllerV2(controller).withdraw(
                address(pool),
                _withdraw
            );
            _expectA0 = _balances[0].add(_a0);
            _expectA1 = _balances[1].add(_a1);
        }

        token0.safeTransfer(msg.sender, _expectA0);
        token1.safeTransfer(msg.sender, _expectA1);
    }

    function getRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return totalLiquidity().mul(1e18).div(totalSupply());
    }

    function _deposit(uint256 token0Amount, uint256 token1Amount) internal {
        if (
            !(token0.balanceOf(address(this)) > token0Amount) &&
            (token0Amount != 0)
        ) token0.safeTransferFrom(msg.sender, address(this), token0Amount);

        if (
            !(token1.balanceOf(address(this)) > token1Amount) &&
            (token1Amount != 0)
        ) token1.safeTransferFrom(msg.sender, address(this), token1Amount);

        _balanceProportion(getLowerTick(), getUpperTick());
    }

    function _convertMatic(uint256 token0Amount, uint256 token1Amount)
        internal
        returns (
            uint256,
            uint256,
            bool
        )
    {
        bool _maticUsed = false;
        uint256 _matic = address(this).balance;
        if (_matic > 0) {
            WETH(wmatic).deposit{value: _matic}();

            if (address(token0) == wmatic) {
                token0Amount = _matic;
                _maticUsed = true;
            } else if (address(token1) == wmatic) {
                token1Amount = _matic;
                _maticUsed = true;
            }
        }
        return (token0Amount, token1Amount, _maticUsed);
    }

    function _refundMatic(uint256 tokenAmount) internal {
        uint256 _refund = WETH(wmatic).balanceOf(address(this)).sub(
            tokenAmount
        );
        WETH(wmatic).withdraw(_refund);
        (bool sent, bytes memory data) = (msg.sender).call{value: _refund}("");
        require(sent, "Failed to refund Matic");
    }

    function _refundUnused(bool _maticUsed) internal returns (uint256) {
        PoolVariables.Info memory _cache;
        _cache.amount0Desired = token0.balanceOf(address(this));
        _cache.amount1Desired = token1.balanceOf(address(this));

        _cache.liquidity = (
            pool.liquidityForAmounts(
                _cache.amount0Desired,
                _cache.amount1Desired,
                getLowerTick(),
                getUpperTick()
            )
        );

        (_cache.amount0, _cache.amount1) = pool.amountsForLiquidity(
            _cache.liquidity,
            getLowerTick(),
            getUpperTick()
        );

        if (_cache.amount0Desired > _cache.amount0)
            if ((address(token0) == address(wmatic)) && _maticUsed)
                _refundMatic(_cache.amount0Desired.sub(_cache.amount0));
            else {
                token0.safeTransfer(
                    msg.sender,
                    _cache.amount0Desired.sub(_cache.amount0)
                );
            }

        if (_cache.amount1Desired > _cache.amount1)
            if ((address(token1) == address(wmatic)) && _maticUsed)
                _refundMatic(_cache.amount1Desired.sub(_cache.amount1));
            else {
                token1.safeTransfer(
                    msg.sender,
                    _cache.amount1Desired.sub(_cache.amount1)
                );
            }
        return _cache.liquidity;
    }

    function _balanceProportion(int24 _tickLower, int24 _tickUpper) internal {
        PoolVariables.Info memory _cache;

        _cache.amount0Desired = token0.balanceOf(address(this));
        _cache.amount1Desired = token1.balanceOf(address(this));

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);

        _cache.liquidity = uint128(
            LiquidityAmounts
            .getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                _cache.amount0Desired
            ).add(
                LiquidityAmounts.getLiquidityForAmount1(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    _cache.amount1Desired
                )
            )
        );

        (_cache.amount0, _cache.amount1) = LiquidityAmounts
        .getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            _cache.liquidity
        );

        //Determine Trade Direction
        bool _zeroForOne = _cache.amount0Desired > _cache.amount0
            ? true
            : false;

        //Determine Amount to swap
        uint256 _amountSpecified = _zeroForOne
            ? (_cache.amount0Desired.sub(_cache.amount0))
            : (_cache.amount1Desired.sub(_cache.amount1));

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

    modifier whenNotPaused() {
        require(paused == false, "paused");
        _;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}
}
