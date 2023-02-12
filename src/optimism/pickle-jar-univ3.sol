// SPDX-License-Identifier: MIT
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
import "../lib/univ3/PoolActions.sol";
import "../lib/reentrancy-guard.sol";
import "../lib/safe-math.sol";
import "../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/univ3/IUniswapV3Pool.sol";
import "../interfaces/univ3/ISwapRouter02.sol";
import "../interfaces/weth.sol";
import "../interfaces/strategy-univ3.sol";

contract PickleJarUniV3 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using PoolVariables for IUniswapV3Pool;

    address public immutable native;

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
        address _native,
        address _governance,
        address _timelock,
        address _controller
    ) public ERC20(_name, _symbol) {
        native = _native;
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());

        governance = _governance;
        timelock = _timelock;
        controller = _controller;
        paused = false;
    }

    function totalLiquidity() public view returns (uint256) {
        return liquidityOfThis().add(IControllerV2(controller).liquidityOf(address(pool)));
    }

    function liquidityOfThis() public view returns (uint256) {
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

    function earn() public {
        require(liquidityOfThis() > 0, "no liquidity here");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        token0.safeTransfer(controller, balance0);
        token1.safeTransfer(controller, balance1);

        IControllerV2(controller).earn(address(pool), balance0, balance1);
    }

    function deposit(uint256 token0Amount, uint256 token1Amount) external payable nonReentrant whenNotPaused {
        bool _ethUsed;
        (token0Amount, token1Amount, _ethUsed) = _convertEth(token0Amount, token1Amount);

        uint256 _liquidity = _depositAndRefundUnused(_ethUsed, token0Amount, token1Amount);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _liquidity;
        } else {
            shares = (_liquidity.mul(totalSupply())).div(IControllerV2(controller).liquidityOf(address(pool)));
        }

        _mint(msg.sender, shares);
    }

    function getProportion() public view returns (uint256) {
        (uint256 a1, uint256 a2) = pool.amountsForLiquidity(1e18, getLowerTick(), getUpperTick());
        return (a2 * (10**18)) / a1;
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
        uint256 b = liquidityOfThis();

        if (b < r) {
            uint256 _withdraw = r.sub(b);
            (uint256 _a0, uint256 _a1) = IControllerV2(controller).withdraw(address(pool), _withdraw);
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

    function _convertEth(uint256 token0Amount, uint256 token1Amount)
        internal
        returns (
            uint256,
            uint256,
            bool
        )
    {
        bool _ethUsed = false;
        uint256 _eth = msg.value;
        if (_eth > 0) {
            WETH(native).deposit{value: _eth}();

            if (address(token0) == native) {
                token0Amount = _eth;
                _ethUsed = true;
            } else if (address(token1) == native) {
                token1Amount = _eth;
                _ethUsed = true;
            }
        }
        return (token0Amount, token1Amount, _ethUsed);
    }

    function _refundEth(uint256 _refund) internal {
        WETH(native).withdraw(_refund);
        (bool sent, ) = (msg.sender).call{value: _refund}("");
        require(sent, "Failed to refund Eth");
    }

    function _depositAndRefundUnused(
        bool _ethUsed,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal returns (uint256 liquidity) {
        if (token0Amount != 0 && (!_ethUsed || address(token0) != native))
            token0.safeTransferFrom(msg.sender, address(this), token0Amount);

        if (token1Amount != 0 && (!_ethUsed || address(token1) != native))
            token1.safeTransferFrom(msg.sender, address(this), token1Amount);

        address strategy = IControllerV2(controller).strategies(address(pool));

        token0.safeApprove(strategy, 0);
        token0.safeApprove(strategy, token0Amount);
        token1.safeApprove(strategy, 0);
        token1.safeApprove(strategy, token1Amount);

        uint256 unusedAmount0;
        uint256 unusedAmount1;
        (liquidity, unusedAmount0, unusedAmount1) = IStrategyUniV3(strategy).balanceAndDeposit(
            token0Amount,
            token1Amount
        );

        if ((address(token0) == address(native)) && _ethUsed) _refundEth(unusedAmount0);
        else {
            token0.safeTransfer(msg.sender, unusedAmount0);
        }
        if ((address(token1) == address(native)) && _ethUsed) _refundEth(unusedAmount1);
        else {
            token1.safeTransfer(msg.sender, unusedAmount1);
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

    receive() external payable {}

    fallback() external payable {}
}
