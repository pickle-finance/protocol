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
    mapping (address => uint256) public playerTokens; //Address => Tickets
    uint256 public totalTickets;
    address[] public winners; //List of Winners
    address public currentWinner;

    IERC20 public constant PICKLE = IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);
    address public owner;

    uint256 drawnBlock = 0;

    constructor() public
    {
      owner = msg.sender;
    }

    modifier onlyOwner {
       require(msg.sender == owner);
       _;
    }

    modifier validSender (uint _amount) {
      require(_amount > 0, "Cannot Participate with no tokens");
      uint256 allowance = PICKLE.allowance(msg.sender, address(this));
      require(allowance >= _amount, "Check the token allowance");
      require(PICKLE.balanceOf(msg.sender) >= _amount, "You cannot transfer more tokens than you have.");
      _;
    }

    /**
     * @notice Changes the Owner of the contract.
     * @param _newOwner The new address of the Owner.
     */
    function changeOwner(address _newOwner) external onlyOwner
    {
      owner = _newOwner;
    }

    /**
     * @notice Purchase Raffle Tickets for address.
     * @param _player Adress purchasing Raffle Tickets.
     * @param _amount Ammount of Raffle Tickets to purchase.
     */
    function buyTickets (address _player, uint256 _amount) public validSender(_amount)
    {
      PICKLE.safeTransferFrom(msg.sender, address(this), _amount);
      if(playerTokens[_player] == 0)
      {
        players.push(_player);
      }

      playerTokens[_player] += _amount;

      totalTickets += _amount;
    }

    /**
     * @notice Purchase Raffle Tickets for self.
     * @param _amount Ammount of Raffle Tickets to purchase.
     */
    function buyTickets(uint256 _amount) external validSender(_amount)
    {
      buyTickets(msg.sender, _amount);
    }

    /**
     * @notice Selects the winner for the Raffle.
     */
    function draw() external onlyOwner
    {
        require (block.number != drawnBlock);
        require (PICKLE.balanceOf(address(this)) > 0, "No Pickles available.");

        drawnBlock = block.number;

        uint256 winningTicket = randomGen();
        uint256 runningTally = 0;

        for(uint i=0; i < players.length; i++)
        {
          if((playerTokens[players[i]] + runningTally) > winningTicket)
          {
            //Winner Found
            currentWinner = players[i];
            winners.push(currentWinner);
            payWinner(currentWinner);
            cleanup();
          }
          else
          {
            //Not the Winner
            runningTally += playerTokens[players[i]];
          }
        }
    }

    /**
     * @notice Transfers funds to the winner and the owner.
     * @param _winner The address of the winner.
     */
    function payWinner(address _winner) internal
    {
      uint _balance = PICKLE.balanceOf(address(this));
      PICKLE.safeTransfer(_winner, _balance / 2);
      PICKLE.safeTransfer(owner, _balance / 2);
    }

    /**
     * @notice Removes values in preparation for the next Raffle.
     */
    function cleanup() internal
    {
      for(uint i = 0; i < players.length; i++)
      {
        delete playerTokens[players[i]];
      }

      delete players;
      totalTickets = 0;
    }

    /**
     * @notice Generates and returns a random number.
     * @return randomNumber A random number between 0 and totalTickets -1.
     */
    function randomGen() view internal returns (uint256 randomNumber) {
        uint256 seed = uint256(blockhash(block.number - 200));
        return(uint256(keccak256(abi.encodePacked(blockhash(block.number-1), seed ))) % totalTickets);
    }
}
