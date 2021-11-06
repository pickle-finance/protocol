pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

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

    function changeOwner(address _newOwner) external onlyOwner
    {
      owner = _newOwner;
    }

    //Buy Tickets for Friends
    function buyTickets (address _player, uint256 _amount) public validSender(_amount)
    {
      PICKLE.safeTransferFrom(_player, address(this), _amount);
      if(playerTokens[_player] == 0)
      {
        players.push(_player);
      }

      playerTokens[_player] += _amount;

      totalTickets += _amount;
    }

    //Buy Tickets for Self
    function buyTickets(uint256 _amount) external validSender(_amount)
    {
      buyTickets(msg.sender, _amount);
    }

    //Draws the Winner
    function draw() external onlyOwner{
        require (block.number != drawnBlock);

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

    function payWinner(address _winner) internal
    {
      uint _balance = PICKLE.balanceOf(address(this));
      PICKLE.safeTransfer(_winner, _balance / 2);
      PICKLE.safeTransfer(owner, _balance / 2);
    }

    function cleanup() internal
    {
      for(uint i = 0; i < players.length; i++)
      {
        delete playerTokens[players[i]];
      }
      delete players;
      totalTickets = 0;
    }
    //Random Number Generator for selecting a winner.
    function randomGen() view internal returns (uint256 randomNumber) {
        uint256 seed = uint256(blockhash(block.number - 200));
        return(uint256(keccak256(abi.encodePacked(blockhash(block.number-1), seed ))) % totalTickets);
    }

}
