const { ethers } = require("ethers");
const { provider } = require("./common");

const send = async (method, payload) => {
  return provider.send(method, payload);
};

const mineBlock = async (timestamp) =>
  send("evm_mine", timestamp && [timestamp]);

const fastForward = async (seconds) => {
  // It's handy to be able to be able to pass big numbers in as we can just
  // query them from the contract, then send them back. If not changed to
  // a number, this causes much larger fast forwards than expected without error.
  if (ethers.BigNumber.isBigNumber(seconds)) seconds = seconds.toNumber();

  // And same with strings.
  if (typeof seconds === "string") seconds = parseInt(seconds);

  await send("evm_increaseTime", [seconds]);

  await mineBlock();
};

const mineBlockToBeTimestamp = async (timestamp) => {
  await send("evm_setNextBlockTimestamp", [timestamp]);
  await mineBlock();
};

const takeSnapshot = async () => {
  const result = await send("evm_snapshot");
  await mineBlock();
  return result;
};

const restoreSnapshot = async (id) => {
  await send("evm_revert", [id]);
  await mineBlock();
};

module.exports = {
  send,
  mineBlock,
  fastForward,
  takeSnapshot,
  restoreSnapshot,
  mineBlockToBeTimestamp,
};
