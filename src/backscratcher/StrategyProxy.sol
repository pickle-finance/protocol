// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards(address) external;

    function rewarded_token() external returns (address);

    function reward_tokens(uint256) external returns (address);
}

interface FeeDistribution {
    function getYield() external;

    function time_cursor() external view returns (uint256);

    function time_cursor_of(address) external view returns (uint256);
}

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
        if (!success) assert(false);
    }
}

contract StrategyProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeProxy for IProxy;

    IProxy public constant proxy =
        IProxy(0xF147b8125d2ef93FB6965Db97D6746952a133934); //locker
    address public constant mintr =
        address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant fxs =
        address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant gauge =
        address(0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce);
    address public constant yveCRV =
        address(0xc5bDdf9843308380375a611c18B50Fb9341f502A); //veFXSVault; need to be changed
    address public constant rewards =
        address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    FeeDistribution public constant feeDistribution =
        FeeDistribution(0xed2647Bbf875b2936AAF95a3F5bbc82819e3d3FE);

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    address public governance;

    uint256 lastTimeCursor;

    constructor() public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
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
            abi.encodeWithSignature(
                "vote_for_gauge_weights(address,uint256)",
                _gauge,
                _amount
            )
        );
    }

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(_token).balanceOf(address(proxy));
        proxy.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature("withdraw(uint256)", _amount)
        );
        _balance = IERC20(_token).balanceOf(address(proxy)).sub(_balance);
        proxy.safeExecute(
            _token,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _balance
            )
        );
        return _balance;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IERC20(_gauge).balanceOf(address(proxy));
    }

    function withdrawAll(address _gauge, address _token)
        external
        returns (uint256)
    {
        require(strategies[_gauge] == msg.sender, "!strategy");
        return withdraw(_gauge, _token, balanceOf(_gauge));
    }

    function deposit(address _gauge, address _token) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(proxy), _balance);
        _balance = IERC20(_token).balanceOf(address(proxy));

        proxy.safeExecute(
            _token,
            0,
            abi.encodeWithSignature("approve(address,uint256)", _gauge, 0)
        );
        proxy.safeExecute(
            _token,
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _gauge,
                _balance
            )
        );
        proxy.safeExecute(
            _gauge,
            0,
            abi.encodeWithSignature("deposit(uint256)", _balance)
        );
    }

    function harvest(address _gauge) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(fxs).balanceOf(address(proxy));
        proxy.safeExecute(
            mintr,
            0,
            abi.encodeWithSignature("mint(address)", _gauge)
        );
        _balance = (IERC20(fxs).balanceOf(address(proxy))).sub(_balance);
        proxy.safeExecute(
            fxs,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _balance
            )
        );
    }

    function claim(address recipient) external {
        require(msg.sender == yveCRV, "!strategy");
        if (now < lastTimeCursor.add(604800)) return;
        address p = address(proxy);
        feeDistribution.claim_many(
            [p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p]
        );
        lastTimeCursor = feeDistribution.time_cursor_of(address(proxy));
        uint256 amount = IERC20(rewards).balanceOf(address(proxy));
        if (amount > 0) {
            proxy.safeExecute(
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
        Gauge(_gauge).claim_rewards(address(proxy));
        proxy.safeExecute(
            _token,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                IERC20(_token).balanceOf(address(proxy))
            )
        );
    }
}
