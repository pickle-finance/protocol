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

import "./interfaces/controllerv2.sol";
import "./lib/erc20.sol";
import "./lib/univ3/PoolActions.sol";
import "./lib/reentrancy-guard.sol";
import "./lib/safe-math.sol";
import "./interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "./interfaces/univ3/IUniswapV3Pool.sol";

contract PickleJarUniV3 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using PoolVariables for IUniswapV3Pool;

    address public governance;
    address public timelock;
    address public controller;

    bool public paused;
    bool public earnAfterDeposit;

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
        earnAfterDeposit = false;
    }

    function totalLiquidity() public view returns (uint256) {
        return liquidityOfThis().add(IControllerV2(controller).liquidityOf(address(pool)));
    }

    function liquidityOfThis() public view returns (uint256) {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));

        return determineLiquidity(_balance0, _balance1);
    }

    function liquidityInProportion() public view returns (uint256) {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));
        return uint256(pool.liquidityForAmounts(_balance0, _balance1, getLowerTick(), getUpperTick()));
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

    function setEarnAfterDeposit(bool _earnAfterDeposit) external {
        require(msg.sender == governance, "!governance");
        earnAfterDeposit = _earnAfterDeposit;
    }

    function earn() public {
        require(liquidityOfThis() > 0, "no liquidity here");

        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));

        if (_balance0 > 0) token0.safeTransfer(controller, _balance0);
        if (_balance1 > 0) token1.safeTransfer(controller, _balance1);

        IControllerV2(controller).earn(address(pool), _balance0, _balance1);
    }

    function deposit(uint256 _token0Amount, uint256 _token1Amount)
        external
        nonReentrant
        whenNotPaused
        checkBalances(_token0Amount, _token1Amount)
    {
        uint256 _pool = totalLiquidity();

        uint256 _liquidity = determineLiquidity(_token0Amount, _token1Amount);

        token0.safeTransferFrom(msg.sender, address(this), _token0Amount);
        token1.safeTransferFrom(msg.sender, address(this), _token1Amount);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _liquidity;
        } else {
            shares = (_liquidity.mul(totalSupply())).div(_pool);
        }

        _mint(msg.sender, shares);

        if (earnAfterDeposit) earn();
    }

    function getProportion() public view returns (uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(1e18, getLowerTick(), getUpperTick());
        return (a2 * (10**18)) / a1;
    }

    function getAmountsForLiquidity(uint128 _liquidity) public view returns (uint256, uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(_liquidity, getLowerTick(), getUpperTick());
        return (a1, a2);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public nonReentrant whenNotPaused {
        uint256 r = (totalLiquidity().mul(_shares)).div(totalSupply());
        (uint256 _expectA0, uint256 _expectA1) = pool.amountsForLiquidity(uint128(r), getLowerTick(), getUpperTick());
        _burn(msg.sender, _shares);
        // Check balance
        uint256[2] memory _balances = [token0.balanceOf(address(this)), token1.balanceOf(address(this))];
        uint256 b = liquidityInProportion();

        if (b < r) {
            uint256 _withdraw = r.sub(b);
            (uint256 _a0, uint256 _a1) = IControllerV2(controller).withdraw(address(pool), _withdraw);
            _expectA0 = _balances[0].add(_a0);
            _expectA1 = _balances[1].add(_a1);
        }

        token0.safeTransfer(msg.sender, _expectA0);
        token1.safeTransfer(msg.sender, _expectA1);
    }

    function determineLiquidity(uint256 _amount0, uint256 _amount1) internal view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(getLowerTick());
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(getUpperTick());

        return
            LiquidityAmounts.getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, _amount0).add(
                LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, _amount1)
            );
    }

    function getRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return totalLiquidity().mul(1e18).div(totalSupply());
    }

    modifier whenNotPaused() {
        require(paused == false, "paused");
        _;
    }

    modifier checkBalances(uint256 _amount0, uint256 _amount1) {
        require(IERC20(token0).allowance(msg.sender, address(this)) >= _amount0, "!Token0Approval");
        require(IERC20(token1).allowance(msg.sender, address(this)) >= _amount1, "!Token1Approval");
        require(IERC20(token0).balanceOf(msg.sender) >= _amount0, "Too Small Token0 Balance");
        require(IERC20(token1).balanceOf(msg.sender) >= _amount1, "Too Small Token1 Balance");
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
}
