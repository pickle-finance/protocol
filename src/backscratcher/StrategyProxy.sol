// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";
import "../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/backscratcher/FraxGauge.sol";
import "hardhat/console.sol";

interface IProxy {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function withdrawLocked(address gauge, uint256 id) external;

    function increaseAmount(uint256) external;
}

library SafeProxy {
    function safeExecute(
        IProxy proxy,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, ) = proxy.execute(to, value, data);
        require(success == true, "execute failed");
    }
}

contract StrategyProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeProxy for IProxy;

    IProxy public proxy = IProxy(0x7600137d41630BB1E35E02332013444302d40Edc);

    address public veFxsVault = address(0xc5bDdf9843308380375a611c18B50Fb9341f502A); //veFXSVault; need to be changed

    // address public constant gaugeFXSRewardsDistributor =
    //     0x278dC748edA1d8eFEf1aDFB518542612b49Fcd34;

    IUniswapV3PositionsNFT public constant nftManager =
        IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant gauge = address(0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce);
    address public constant rewards = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant feeDistribution = 0xed2647Bbf875b2936AAF95a3F5bbc82819e3d3FE;

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    address public governance;

    constructor() public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setFXSVault(address _vault) external {
        require(msg.sender == governance, "!governance");
        veFxsVault = _vault;
    }

    function setLockerProxy(address _proxy) external {
        require(msg.sender == governance, "!governance");
        proxy = IProxy(_proxy);
    }

    function approveStrategy(address _gauge, address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = _strategy;
    }

    function revokeStrategy(address _gauge) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = address(0);
    }

    function approveVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = true;
    }

    function revokeVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = false;
    }

    function lock() external {
        uint256 amount = IERC20(fxs).balanceOf(address(proxy));
        if (amount > 0) proxy.increaseAmount(amount);
    }

    function vote(address _gauge, uint256 _amount) public {
        require(voters[msg.sender], "!voter");
        proxy.safeExecute(
            gauge,
            0,
            abi.encodeWithSignature("vote_for_gauge_weights(address,uint256)", _gauge, _amount)
        );
    }

    function withdrawV3(address _gauge, uint256 _tokenId) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("withdrawLocked(uint256)", _tokenId));
        (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(_tokenId);
        if (_liquidity > 0) {
            proxy.safeExecute(
                address(nftManager),
                0,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    address(proxy),
                    msg.sender,
                    _tokenId
                )
            );
        }
        return _liquidity;
    }

    function withdrawV2(
        address _gauge,
        address _token,
        bytes32 _kek_id
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");

        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("withdrawLocked(bytes32)", _kek_id));

        LockedStake[] memory lockedStakes = IFraxGaugeUniV2(_gauge).lockedStakesOf(address(proxy));

        LockedStake memory thisStake;

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            if (_kek_id == lockedStakes[i].kek_id) {
                thisStake = lockedStakes[i];
                break;
            }
        }
        require(thisStake.liquidity != 0, "kek_id not found");
        if (thisStake.liquidity > 0) {
            proxy.safeExecute(
                _token,
                0,
                abi.encodeWithSignature("transfer(address,uint256)", msg.sender, thisStake.liquidity)
            );
        }
        return thisStake.liquidity;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IFraxGaugeBase(_gauge).lockedLiquidityOf(address(proxy));
    }

    function lockedNFTsOf(address _gauge) public view returns (LockedNFT[] memory) {
        return IFraxGaugeUniV3(_gauge).lockedNFTsOf(address(proxy));
    }

    function lockedStakesOf(address _gauge) public view returns (LockedStake[] memory) {
        return IFraxGaugeUniV2(_gauge).lockedStakesOf(address(proxy));
    }

    function withdrawAllV3(address _gauge, address _token) external returns (uint256 amount) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedNFT[] memory lockedNfts = IFraxGaugeUniV3(_gauge).lockedNFTsOf(address(proxy));
        for (uint256 i = 0; i < lockedNfts.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV3(_gauge, lockedNfts[i].token_id);
            amount = amount.add(_withdrawnLiquidity);
        }
    }

    function withdrawAllV2(address _gauge, address _token) external returns (uint256 amount) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedStake[] memory lockedStakes = IFraxGaugeUniV2(_gauge).lockedStakesOf(address(proxy));

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV2(_gauge, _token, lockedStakes[i].kek_id);
            amount = amount.add(_withdrawnLiquidity);
        }
    }

    function depositV3(
        address _gauge,
        uint256 _tokenId,
        uint256 _secs
    ) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        nftManager.safeTransferFrom(address(this), address(proxy), _tokenId);

        proxy.safeExecute(
            address(nftManager),
            0,
            abi.encodeWithSignature("approve(address,uint256)", _gauge, _tokenId)
        );
        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("stakeLocked(uint256,uint256)", _tokenId, _secs));
    }

    function depositV2(
        address _gauge,
        address _token,
        uint256 _secs
    ) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(proxy), _balance);
        _balance = IERC20(_token).balanceOf(address(proxy));

        proxy.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, 0));
        proxy.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, _balance));
        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("stakeLocked(uint256,uint256)", _balance, _secs));
    }

    function harvest(address _gauge, address[] calldata _tokens) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256[] memory _balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = IERC20(_tokens[i]).balanceOf(address(proxy));
        }

        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("getReward()"));

        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = (IERC20(_tokens[i]).balanceOf(address(proxy))).sub(_balances[i]);
            proxy.safeExecute(
                _tokens[i],
                0,
                abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balances[i])
            );
        }
    }

    function claim(address recipient) external {
        require(msg.sender == veFxsVault, "!vault");

        proxy.safeExecute(feeDistribution, 0, abi.encodeWithSignature("getYield()"));

        uint256 amount = IERC20(rewards).balanceOf(address(proxy));
        if (amount > 0) {
            proxy.safeExecute(rewards, 0, abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
        }
    }

    function claimRewards(address _gauge, address _token) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("getReward()"));

        proxy.safeExecute(
            _token,
            0,
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, IERC20(_token).balanceOf(address(proxy)))
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data) public payable returns (bytes memory response) {
        require(msg.sender == governance, "!governance");
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
}
