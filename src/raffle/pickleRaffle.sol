pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

/**
 * @title A Raffle for Pickles
 * @author Cipio
 * @notice Use this contract to participate in a 50/50 Raffle. The Winner gets 50%, the other 50% gets used to burn Corn.
 */
contract pickleRaffle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] public players;
    uint256 public numPlayers;
    mapping(address => uint256) public playerTokens; //Address => Tickets
    uint256 public totalTickets;
    WinnerInfo[] public winners; //List of Winners
    address public currentWinner;
    bool public depositsEnabled;

    IERC20 public constant PICKLE =
        IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);
    address public owner;

    uint256 drawnBlock = 0;

    struct WinnerInfo {
        address winner;
        uint256 amount;
        uint256 timestamp;
        uint256 numParticipants;
    }

    constructor() public {
        owner = msg.sender;
        depositsEnabled = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier validSender(uint256 _amount) {
        require(_amount > 0, "Cannot Participate with no tokens");
        uint256 allowance = PICKLE.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        require(
            PICKLE.balanceOf(msg.sender) >= _amount,
            "You cannot transfer more tokens than you have."
        );
        require(depositsEnabled, "Deposits are currently Disabled.");
        _;
    }

    /**
     * @notice Changes the Owner of the contract.
     * @param _newOwner The new address of the Owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    /**
     * @notice Sets whether depsits are enabled or not.
     * @param _deposits Sets if deposits are allowed.
     */
    function enableDeposits(bool _deposits) external onlyOwner {
        depositsEnabled = _deposits;
    }

    /**
     * @notice Purchase Raffle Tickets for address.
     * @param _player Adress purchasing Raffle Tickets.
     * @param _amount Ammount of Raffle Tickets to purchase.
     */
    function buyTickets(address _player, uint256 _amount)
        public
        validSender(_amount)
    {
        PICKLE.safeTransferFrom(msg.sender, address(this), _amount);
        if (playerTokens[_player] == 0) {
            players.push(_player);
            numPlayers = numPlayers.add(1);
        }

        playerTokens[_player] = playerTokens[_player].add(_amount);

        totalTickets = totalTickets.add(_amount);
    }

    /**
     * @notice Purchase Raffle Tickets for self.
     * @param _amount Ammount of Raffle Tickets to purchase.
     */
    function buyTickets(uint256 _amount) external validSender(_amount) {
        buyTickets(msg.sender, _amount);
    }

    /**
     * @notice Selects the winner for the Raffle.
     */
    function draw() external onlyOwner {
        require(block.number != drawnBlock);
        require(PICKLE.balanceOf(address(this)) > 0, "No Pickles available.");

        drawnBlock = block.number;

        uint256 winningTicket = randomGen();
        uint256 runningTally = 0;

        for (uint256 i = 0; i < players.length; i++) {
            if (playerTokens[players[i]].add(runningTally) > winningTicket) {
                //Winner Found
                payWinner(players[i]);
                cleanup();
            } else {
                //Not the Winner
                runningTally = runningTally.add(playerTokens[players[i]]);
            }
        }
    }

    /**
     * @notice Transfers funds to the winner and the owner.
     * @param _winner The address of the winner.
     */
    function payWinner(address _winner) internal {
        currentWinner = _winner;

        uint256 _balance = PICKLE.balanceOf(address(this));
        uint256 _payout = _balance.mul(4).div(5);

        winners.push(WinnerInfo(currentWinner, _payout, now, players.length));

        PICKLE.safeTransfer(_winner, _payout);
        PICKLE.safeTransfer(owner, _balance.div(5));
    }

    /**
     * @notice Removes values in preparation for the next Raffle.
     */
    function cleanup() internal {
        for (uint256 i = 0; i < players.length; i++) {
            delete playerTokens[players[i]];
        }

        delete players;
        totalTickets = 0;
        numPlayers = 0;
    }

    /**
     * @notice Generates and returns a random number.
     * @return randomNumber A random number between 0 and totalTickets -1.
     */
    function randomGen() internal view returns (uint256 randomNumber) {
        uint256 seed = uint256(blockhash(block.number - 200));
        return (uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
        ) % totalTickets);
    }
}
