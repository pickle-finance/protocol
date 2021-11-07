const {expect, getContractAt, deployContract, unlockAccount, toWei} = require("../utils/testHelper");
const {getWantFromWhale} = require("../utils/setupHelper");
const {ZERO_ADDRESS, NULL_ADDRESS} = require("../utils/constants");
const {ethers} = require("hardhat");

const PICKLE = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const whaleAddr = "0x2511132954b11fbc6bd56e6ec57161406ea31631";

let owner, user, raffle, pickleToken;
let winner1, winner2;

describe(`Raffle Tests`, () => {
  before("Setup contracts", async () => {
    [owner, user] = await hre.ethers.getSigners();

    pickleToken = await getContractAt("ERC20", PICKLE);

    raffle = await deployContract("pickleRaffle");
    console.log("✅ Raffle is deployed at ", raffle.address);
  });

  it("Should have good initial values", async () => {
    expect(await raffle.currentWinner()).to.be.eq(ZERO_ADDRESS, "current winner is correct");
    expect(await raffle.totalTickets()).to.be.eq(0, "Initial Total Tickets is correct");
  });

  it("Should deposit correctly (for other)", async () => {
    await getWantFromWhale(PICKLE, toWei(1000), owner, whaleAddr);
    const _pickles = await pickleToken.balanceOf(owner.address);
    console.log("Owner Tokens: %s\n", _pickles);
    await pickleToken.approve(raffle.address, _pickles);
    await raffle["buyTickets(address,uint256)"](user.address, _pickles);
    console.log("User Raffle Tickets after deposit: %s\n", (await raffle.playerTokens(user.address)).toString());
    expect(await raffle.playerTokens(user.address)).to.be.eq(_pickles, "deposit tokens for user is correct");
    expect(await raffle.playerTokens(owner.address)).to.be.eq(0, "deposit tokens for owner is correct");
    expect(await pickleToken.balanceOf(owner.address)).to.be.eq(0, "Owner has no more pickles correct");
    expect(await raffle.totalTickets()).to.be.eq(_pickles, "total tickets is correct");
  });

  it("Should deposit correctly (self)", async () => {
    await getWantFromWhale(PICKLE, toWei(1000), owner, whaleAddr);
    const _pickles = await pickleToken.balanceOf(owner.address);
    console.log("Owner Tokens: %s\n", _pickles);
    await pickleToken.approve(raffle.address, _pickles);
    await raffle["buyTickets(uint256)"](_pickles);
    console.log("Owner Raffle Tickets after deposit: %s\n", (await raffle.playerTokens(owner.address)).toString());
    expect(await raffle.playerTokens(user.address)).to.be.eq(_pickles, "deposit tokens for user is correct");
    expect(await raffle.playerTokens(owner.address)).to.be.eq(_pickles, "deposit tokens for owner is correct");
    expect(await pickleToken.balanceOf(owner.address)).to.be.eq(0, "Owner has no more pickles correct");
    expect(await raffle.totalTickets()).to.be.eq(_pickles.mul(2), "total tickets is correct");
  });

  it("Draw correctly", async () => {
    expect(await pickleToken.balanceOf(user.address)).to.be.eq(0, "User has no pickles correct");
    expect(await pickleToken.balanceOf(owner.address)).to.be.eq(0, "Owner has no pickles correct");
    const _pickles = await raffle.playerTokens(owner.address);
    const _totalTickets = await raffle.totalTickets();
    const _playerLength = await raffle.numPlayers();
    console.log("Player count: %s\n", _playerLength);
    const players = await raffle.players(0);
    console.log("Player list: %s\n", players);
    await raffle.draw();
    let theWinner = await raffle.currentWinner();
    console.log("The winner is: %s\n", theWinner.toString());

    const _blockNum = await ethers.provider.getBlockNumber();
    const _block = await ethers.provider.getBlock(_blockNum);
    const _timestamp = _block.timestamp;
    const _payout = _totalTickets.mul(4).div(5);

    winner1 = new Object();
    winner1.address = theWinner;
    winner1.payout = _payout;
    winner1.timestamp = _timestamp;
    winner1.playerLength = _playerLength;

    if (theWinner == user.address) {
      expect(await pickleToken.balanceOf(user.address)).to.be.eq(_payout, "deposit tokens for user is correct");
      expect(await pickleToken.balanceOf(owner.address)).to.be.eq(
        _totalTickets.div(5),
        "deposit tokens for owner is correct"
      );
    } else {
      expect(await pickleToken.balanceOf(user.address)).to.be.eq(0, "deposit tokens for user is correct");
      expect(await pickleToken.balanceOf(owner.address)).to.be.eq(_totalTickets, "deposit tokens for owner is correct");
    }
  });

  it("Clear correctly after a Draw", async () => {
    expect(await raffle.playerTokens(user.address)).to.be.eq(0, "deposit tokens for user is correct");
    expect(await raffle.playerTokens(owner.address)).to.be.eq(0, "deposit tokens for owner is correct");
    expect(await raffle.totalTickets()).to.be.eq(0, "total tickets is correct");
  });

  it("Should deposit multiple times correctly ", async () => {
    await getWantFromWhale(PICKLE, toWei(2000), owner, whaleAddr);
    const _pickles = await pickleToken.balanceOf(owner.address);
    console.log("Owner Tokens: %s\n", _pickles);
    await pickleToken.approve(raffle.address, _pickles);
    await raffle["buyTickets(address,uint256)"](user.address, toWei(1000));
    console.log("User Raffle Tickets after deposit: %s\n", (await raffle.playerTokens(user.address)).toString());

    console.log("Owner Tokens: %s\n", _pickles);
    await pickleToken.approve(raffle.address, _pickles);
    await raffle["buyTickets(address,uint256)"](user.address, toWei(1000));
    console.log("User Raffle Tickets after deposit: %s\n", (await raffle.playerTokens(user.address)).toString());

    expect(await raffle.playerTokens(user.address)).to.be.eq(toWei(2000), "deposit tokens for user is correct");
    expect(await raffle.totalTickets()).to.be.eq(toWei(2000), "total tickets is correct");
  });

  it("draw multiple times correctly ", async () => {
    startingUserBalance = await pickleToken.balanceOf(user.address);
    startingOwnerBalance = await pickleToken.balanceOf(owner.address);
    const _totalTickets = await raffle.totalTickets();
    const _playerLength = await raffle.numPlayers();

    await raffle.draw();
    let theWinner = await raffle.currentWinner();
    console.log("The winner is: %s\n", theWinner.toString());

    const _blockNum = await ethers.provider.getBlockNumber();
    const _block = await ethers.provider.getBlock(_blockNum);
    const _timestamp = _block.timestamp;

    const _payout = _totalTickets.mul(4).div(5);

    winner2 = new Object();
    winner2.address = theWinner;
    winner2.payout = _payout;
    winner2.timestamp = _timestamp;
    winner2.playerLength = _playerLength;

    expect(theWinner).to.be.eq(user.address, "user won correct");
    expect(await pickleToken.balanceOf(user.address)).to.be.eq(
      startingUserBalance.add(_payout),
      "deposit tokens for user is correct"
    );
    expect(await pickleToken.balanceOf(owner.address)).to.be.eq(
      startingOwnerBalance.add(_totalTickets.div(5)),
      "deposit tokens for owner is correct"
    );
  });

  it("Clear correctly after a Draw", async () => {
    expect(await raffle.playerTokens(user.address)).to.be.eq(0, "deposit tokens for user is correct");
    expect(await raffle.playerTokens(owner.address)).to.be.eq(0, "deposit tokens for owner is correct");
    expect(await raffle.totalTickets()).to.be.eq(0, "total tickets is correct");
  });

  it("Multiple Drawing Winners correctly", async () => {
    let winnerList1 = await raffle.winners(0);
    let winnerList2 = await raffle.winners(1);

    expect(winnerList1.winner).to.be.eq(winner1.address, "winner1 list address is correct");
    expect(winnerList1.amount).to.be.eq(winner1.payout, "winner1 list amount is correct");
    expect(winnerList1.timestamp).to.be.eq(winner1.timestamp, "winner1 list timestamp is correct");
    expect(winnerList1.numParticipants).to.be.eq(winner1.playerLength, "winner1 list numParticipants is correct");
    expect(winnerList2.winner).to.be.eq(winner2.address, "winner2 list address is correct");
    expect(winnerList2.amount).to.be.eq(winner2.payout, "winner2 list amount is correct");
    expect(winnerList2.timestamp).to.be.eq(winner2.timestamp, "winner2 list timestamp is correct");
    expect(winnerList2.numParticipants).to.be.eq(winner2.playerLength, "winner2 list numParticipants is correct");
  });

  it("disable deposits correctly", async () => {
    await raffle.enableDeposits(false);
    const _pickles = await pickleToken.balanceOf(owner.address);
    await pickleToken.approve(raffle.address, _pickles);
    await expect(raffle["buyTickets(address,uint256)"](user.address, _pickles)).to.be.revertedWith(
      "Deposits are currently Disabled."
    );
  });
});
