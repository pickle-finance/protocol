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

    raffle = await deployContract(
      "pickleRaffle"
    );
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
    await raffle.draw();
    let theWinner = await raffle.currentWinner();
    console.log("The winner is: %s\n", (theWinner.toString()));
    winner1 = theWinner;

    if(theWinner == user.address)
    {
      expect(await pickleToken.balanceOf(user.address)).to.be.eq(_pickles, "deposit tokens for user is correct");
      expect(await pickleToken.balanceOf(owner.address)).to.be.eq(_pickles, "deposit tokens for owner is correct");
    }
    else
    {
      expect(await pickleToken.balanceOf(user.address)).to.be.eq(0, "deposit tokens for user is correct");
      expect(await pickleToken.balanceOf(owner.address)).to.be.eq(_pickles.mul(2), "deposit tokens for owner is correct");
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

    await raffle.draw();
    let theWinner = await raffle.currentWinner();
    console.log("The winner is: %s\n", (theWinner.toString()));
    winner2 = theWinner;

    expect(theWinner).to.be.eq(user.address, "user won correct");
    expect(await pickleToken.balanceOf(user.address)).to.be.eq(startingUserBalance.add(toWei(1000)), "deposit tokens for user is correct");
    expect(await pickleToken.balanceOf(owner.address)).to.be.eq(startingOwnerBalance.add(toWei(1000)), "deposit tokens for owner is correct");

  });

  it("Clear correctly after a Draw", async () => {
    expect(await raffle.playerTokens(user.address)).to.be.eq(0, "deposit tokens for user is correct");
    expect(await raffle.playerTokens(owner.address)).to.be.eq(0, "deposit tokens for owner is correct");
    expect(await raffle.totalTickets()).to.be.eq(0, "total tickets is correct");
  });

  it("Multiple Drawing Winners correctly", async () => {
    expect(await raffle.winners(0)).to.be.eq(winner1, "winner1 list is correct");
    expect(await raffle.winners(1)).to.be.eq(winner2, "winner2 list is correct");
  });
});
