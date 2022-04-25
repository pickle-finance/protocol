// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";
import "../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/backscratcher/FraxGauge.sol";

interface IProxy {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

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

    IProxy public proxy;

    address public veFxsVault;

    // address public constant gaugeFXSRewardsDistributor =
    //     0x278dC748edA1d8eFEf1aDFB518542612b49Fcd34;

    IUniswapV3PositionsNFT public constant nftManager =
        IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant rewards = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public gauge = address(0x3669C421b77340B2979d1A00a792CC2ee0FcE737);
    address public feeDistribution = 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872;

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    mapping(address => bytes) private claimRewardsString;
    address public governance;

    // TODO How much FXS tokens to give to backscratcher?
    uint256 public keepFXS = 1000;
    uint256 public constant keepFXSMax = 10000;

    constructor() public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setKeepFXS(uint256 _keepFXS) external {
        require(msg.sender == governance, "!governance");
        keepFXS = _keepFXS;
    }

    function setFXSVault(address _vault) external {
        require(msg.sender == governance, "!governance");
        veFxsVault = _vault;
    }

    function setLocker(address _proxy) external {
        require(msg.sender == governance, "!governance");
        proxy = IProxy(_proxy);
    }

    function setGauge(address _gauge) external {
        require(msg.sender == governance, "!governance");
        gauge = _gauge;
    }

    function setFeeDistribution(address _feeDistribution) external {
        require(msg.sender == governance, "!governance");
        feeDistribution = _feeDistribution;
    }

    function approveStrategy(
        address _gauge,
        address _strategy,
        bytes calldata claimString
    ) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = _strategy;
        claimRewardsString[_gauge] = claimString;
    }

    function revokeStrategy(address _gauge) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = address(0);
        claimRewardsString[_gauge] = "";
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

    function withdrawV3(
        address _gauge,
        uint256 _tokenId,
        address[] memory _rewardTokens
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");

        uint256[] memory _balances = new uint256[](_rewardTokens.length);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = IERC20(_rewardTokens[i]).balanceOf(address(proxy));
        }

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

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = (IERC20(_rewardTokens[i]).balanceOf(address(proxy))).sub(_balances[i]);
            if (_balances[i] > 0)
                proxy.safeExecute(
                    _rewardTokens[i],
                    0,
                    abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balances[i])
                );
        }
        return _liquidity;
    }

    function withdrawV2(
        address _gauge,
        address _token,
        bytes32 _kek_id,
        address[] memory _rewardTokens
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");

        uint256[] memory _balances = new uint256[](_rewardTokens.length);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = IERC20(_rewardTokens[i]).balanceOf(address(proxy));
        }

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

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = (IERC20(_rewardTokens[i]).balanceOf(address(proxy))).sub(_balances[i]);
            if (_balances[i] > 0)
                proxy.safeExecute(
                    _rewardTokens[i],
                    0,
                    abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balances[i])
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

    function withdrawAllV3(address _gauge, address[] calldata _rewardTokens) external returns (uint256 amount) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedNFT[] memory lockedNfts = IFraxGaugeUniV3(_gauge).lockedNFTsOf(address(proxy));
        for (uint256 i = 0; i < lockedNfts.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV3(_gauge, lockedNfts[i].token_id, _rewardTokens);
            amount = amount.add(_withdrawnLiquidity);
        }
    }

    function withdrawAllV2(
        address _gauge,
        address _token,
        address[] calldata _rewardTokens
    ) external returns (uint256 amount) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedStake[] memory lockedStakes = IFraxGaugeUniV2(_gauge).lockedStakesOf(address(proxy));

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV2(_gauge, _token, lockedStakes[i].kek_id, _rewardTokens);
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

        proxy.safeExecute(_gauge, 0, claimRewardsString[_gauge]);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = (IERC20(_tokens[i]).balanceOf(address(proxy))).sub(_balances[i]);
            if (_balances[i] > 0) {
                uint256 _swapAmount = _balances[i];
                if (_tokens[i] == fxs) {
                    uint256 _amountKeep = _balances[i].mul(keepFXS).div(keepFXSMax);
                    _swapAmount = _balances[i].sub(_amountKeep);

                    proxy.safeExecute(
                        _tokens[i],
                        0,
                        abi.encodeWithSignature("transfer(address,uint256)", veFxsVault, _amountKeep)
                    );
                }

                proxy.safeExecute(
                    _tokens[i],
                    0,
                    abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _swapAmount)
                );
            }
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

        proxy.safeExecute(_gauge, 0, claimRewardsString[_gauge]);

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
