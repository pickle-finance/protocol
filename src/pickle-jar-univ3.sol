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

import "./interfaces/controller.sol";
import "./lib/erc20.sol";
import "./lib/reentrancy-guard.sol";
import "./lib/safe-math.sol";
import "./interfaces/uniswapv3.sol";

contract PickleJarV2 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public timelock;
    address public controller;

    bool public paused;
    bool public earnAfterDeposit;

    uint256 public totalLiquidityOfThis;
    mapping(address => uint256) liquidityOfUser;

    IUniV3Pool public pool;

    IUniswapV3PositionsNFT public nftManager = IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); // UniV3 uses an NFT

    int24 public uni_tick_lower;
    int24 public uni_tick_upper;

    struct UniV3NFTs {
        uint256 token_id; // for Uniswap V3 LPs
        uint256 liquidity;
        int24 tick_lower;
        int24 tick_upper;
    }

    UniV3NFTs[] public lockedNfts;

    constructor(
        string memory _name,
        string memory _symbol,
        address _pool,
        int24 _uni_tick_lower,
        int24 _uni_tick_upper,
        address _governance,
        address _timelock,
        address _controller
    ) public ERC20(_name, _symbol) {
        pool = IUniV3Pool(_pool);
        uni_tick_lower = _uni_tick_lower;
        uni_tick_upper = _uni_tick_upper;

        governance = _governance;
        timelock = _timelock;
        controller = _controller;
        paused = false;
        earnAfterDeposit = false;
    }

    function balance() public view returns (uint256) {
        return totalLiquidityOfThis.add(IController(controller).liquidityOf(address(pool)));
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
        for (; lockedNfts.length > 0; ) {
            nftManager.safeTransferFrom(address(this), controller, lockedNfts[lockedNfts.length - 1].token_id);
            lockedNfts.pop();
        }
        IController(controller).earn(address(pool));
    }

    function deposit(uint256 _token_id) external nonReentrant whenNotPaused {
        (, uint256 liquidity, int24 tick_lower, int24 tick_upper) = checkUniV3NFT(_token_id, true); // Should throw if false

        lockedNfts.push(UniV3NFTs(_token_id, liquidity, tick_lower, tick_upper));

        totalLiquidityOfThis = totalLiquidityOfThis.add(liquidity);
        liquidityOfUser[msg.sender] = liquidityOfUser[msg.sender].add(liquidity);

        nftManager.safeTransferFrom(msg.sender, address(this), _token_id);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = liquidity;
        } else {
            shares = (liquidity.mul(totalSupply())).div(balance());
        }
        _mint(msg.sender, shares);

        if (earnAfterDeposit) earn();
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public nonReentrant whenNotPaused {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(pool), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
    }

    function getRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return balance().mul(1e18).div(totalSupply());
    }

    function checkUniV3NFT(uint256 token_id, bool fail_if_false)
        internal
        view
        returns (
            bool is_valid,
            uint256 liquidity,
            int24 tick_lower,
            int24 tick_upper
        )
    {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint256 _liquidity,
            ,
            ,
            ,

        ) = nftManager.positions(token_id);

        // Set initially
        is_valid = false;
        liquidity = _liquidity;

        // Do the checks
        if (
            (token0 == pool.token0()) &&
            (token1 == pool.token1()) &&
            (fee == pool.fee()) &&
            (tickLower == uni_tick_lower) &&
            (tickUpper == uni_tick_upper)
        ) {
            is_valid = true;
        } else {
            if (fail_if_false) {
                revert("Invalid token");
            }
        }
        return (is_valid, liquidity, tickLower, tickUpper);
    }

    modifier whenNotPaused() {
        require(paused == false, "paused");
        _;
    }
}
