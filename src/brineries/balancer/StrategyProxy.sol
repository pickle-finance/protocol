// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11; //^0.6.7
pragma experimental ABIEncoderV2;

import "../../lib/safe-math.sol";
import "../../lib/erc20.sol";
import "../../interfaces/univ3/IUniswapV3PositionsNFT.sol";
import "../interfaces/brineries/balancer/FraxGauge.sol";

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

    IProxy public locker;

    address public veBALVault;
    address public minter;

    // address public constant gaugeFXSRewardsDistributor =
    //     0x278dC748edA1d8eFEf1aDFB518542612b49Fcd34;

    IUniswapV3PositionsNFT public constant nftManager =
        IUniswapV3PositionsNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address public constant bal =
        address(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);
    address public constant rewards =
        address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public gauge = address(0x3669C421b77340B2979d1A00a792CC2ee0FcE737);
    address public feeDistribution = 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872;

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    address public governance;

    // TODO How much FXS tokens to give to backscratcher?
    uint256 public keepBAL = 1000;
    uint256 public constant keepBALMax = 10000;

    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setKeepBAL(uint256 _keepBAL) external {
        require(msg.sender == governance, "!governance");
        keepBAL = _keepBAL;
    }

    function setBALVault(address _vault) external {
        require(msg.sender == governance, "!governance");
        veBALVault = _vault;
    }

    function setLocker(address _locker) external {
        require(msg.sender == governance, "!governance");
        locker = IProxy(_locker);
    }

    function setMinter(address _minter) external {
        require(msg.sender == governance, "!governance");
        minter = _minter;
    }

    function setGauge(address _gauge) external {
        require(msg.sender == governance, "!governance");
        gauge = _gauge;
    }

    function setFeeDistribution(address _feeDistribution) external {
        require(msg.sender == governance, "!governance");
        feeDistribution = _feeDistribution;
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

    function lock(uint256 _amount) external {
        require(msg.sender == minter && _amount > 0, "!minter || !amt");

        IERC20(bal).safeTransferFrom(msg.sender, address(locker), _amount);
        locker.increaseAmount(_amount);
    }

    function vote(address _gauge, uint256 _amount) public {
        require(voters[msg.sender], "!voter");
        locker.safeExecute(
            gauge,
            0,
            abi.encodeWithSignature(
                "vote_for_gauge_weights(address,uint256)",
                _gauge,
                _amount
            )
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
            _balances[i] = IERC20(_rewardTokens[i]).balanceOf(address(locker));
        }

        locker.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature("withdrawLocked(uint256)", _tokenId)
        );

        (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(
            _tokenId
        );

        if (_liquidity > 0) {
            locker.safeExecute(
                address(nftManager),
                0,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    address(locker),
                    msg.sender,
                    _tokenId
                )
            );
        }

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = (IERC20(_rewardTokens[i]).balanceOf(address(locker)))
                .sub(_balances[i]);
            if (_balances[i] > 0)
                locker.safeExecute(
                    _rewardTokens[i],
                    0,
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        msg.sender,
                        _balances[i]
                    )
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
            _balances[i] = IERC20(_rewardTokens[i]).balanceOf(address(locker));
        }

        locker.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature("withdrawLocked(bytes32)", _kek_id)
        );
        LockedStake[] memory lockedStakes = IFraxGaugeUniV2(_gauge)
            .lockedStakesOf(address(locker));
        LockedStake memory thisStake;

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            if (_kek_id == lockedStakes[i].kek_id) {
                thisStake = lockedStakes[i];
                break;
            }
        }
        require(thisStake.liquidity != 0, "kek_id not found");

        if (thisStake.liquidity > 0) {
            locker.safeExecute(
                _token,
                0,
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    msg.sender,
                    thisStake.liquidity
                )
            );
        }

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _balances[i] = (IERC20(_rewardTokens[i]).balanceOf(address(locker)))
                .sub(_balances[i]);
            if (_balances[i] > 0)
                locker.safeExecute(
                    _rewardTokens[i],
                    0,
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        msg.sender,
                        _balances[i]
                    )
                );
        }
        return thisStake.liquidity;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IFraxGaugeBase(_gauge).lockedLiquidityOf(address(locker));
    }

    function lockedNFTsOf(address _gauge)
        public
        view
        returns (LockedNFT[] memory)
    {
        return IFraxGaugeUniV3(_gauge).lockedNFTsOf(address(locker));
    }

    function lockedStakesOf(address _gauge)
        public
        view
        returns (LockedStake[] memory)
    {
        return IFraxGaugeUniV2(_gauge).lockedStakesOf(address(locker));
    }

    function withdrawAllV3(address _gauge, address[] calldata _rewardTokens)
        external
        returns (uint256 amount)
    {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedNFT[] memory lockedNfts = IFraxGaugeUniV3(_gauge).lockedNFTsOf(
            address(locker)
        );
        for (uint256 i = 0; i < lockedNfts.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV3(
                _gauge,
                lockedNfts[i].token_id,
                _rewardTokens
            );
            amount = amount.add(_withdrawnLiquidity);
        }
    }

    function withdrawAllV2(
        address _gauge,
        address _token,
        address[] calldata _rewardTokens
    ) external returns (uint256 amount) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        LockedStake[] memory lockedStakes = IFraxGaugeUniV2(_gauge)
            .lockedStakesOf(address(locker));

        for (uint256 i = 0; i < lockedStakes.length; i++) {
            uint256 _withdrawnLiquidity = withdrawV2(
                _gauge,
                _token,
                lockedStakes[i].kek_id,
                _rewardTokens
            );
            amount = amount.add(_withdrawnLiquidity);
        }
    }

    function depositV3(
        address _gauge,
        uint256 _tokenId,
        uint256 _secs
    ) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        nftManager.safeTransferFrom(address(this), address(locker), _tokenId);

        locker.safeExecute(
            address(nftManager),
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _gauge,
                _tokenId
            )
        );
        locker.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature(
                "stakeLocked(uint256,uint256)",
                _tokenId,
                _secs
            )
        );
    }

    function depositV2(
        address _gauge,
        address _token,
        uint256 _secs
    ) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(locker), _balance);
        _balance = IERC20(_token).balanceOf(address(locker));

        locker.safeExecute(
            _token,
            0,
            abi.encodeWithSignature("approve(address,uint256)", _gauge, 0)
        );
        locker.safeExecute(
            _token,
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _gauge,
                _balance
            )
        );
        locker.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature(
                "stakeLocked(uint256,uint256)",
                _balance,
                _secs
            )
        );
    }

    function harvest(address _gauge, address[] calldata _tokens) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256[] memory _balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = IERC20(_tokens[i]).balanceOf(address(locker));
        }

        locker.safeExecute(_gauge, 0, abi.encodeWithSignature("getReward()"));

        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = (IERC20(_tokens[i]).balanceOf(address(locker))).sub(
                _balances[i]
            );
            if (_balances[i] > 0) {
                uint256 _swapAmount = _balances[i];
                if (_tokens[i] == bal) {
                    uint256 _amountKeep = _balances[i].mul(keepBAL).div(
                        keepBALMax
                    );
                    _swapAmount = _balances[i].sub(_amountKeep);
                    locker.safeExecute(
                        _tokens[i],
                        0,
                        abi.encodeWithSignature(
                            "transfer(address,uint256)",
                            veBALVault,
                            _amountKeep
                        )
                    );
                }

                locker.safeExecute(
                    _tokens[i],
                    0,
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        msg.sender,
                        _swapAmount
                    )
                );
            }
        }
    }

    function claim(address recipient) external {
        require(msg.sender == veBALVault, "!vault");

        locker.safeExecute(
            feeDistribution,
            0,
            abi.encodeWithSignature("getYield()")
        );

        uint256 amount = IERC20(rewards).balanceOf(address(locker));
        if (amount > 0) {
            locker.safeExecute(
                rewards,
                0,
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    recipient,
                    amount
                )
            );
        }
    }

    function claimRewards(address _gauge, address _token) external {
        require(strategies[_gauge] == msg.sender, "!strategy");

        locker.safeExecute(_gauge, 0, abi.encodeWithSignature("getReward()"));

        locker.safeExecute(
            _token,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                IERC20(_token).balanceOf(address(locker))
            )
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

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == governance, "!governance");
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
}
