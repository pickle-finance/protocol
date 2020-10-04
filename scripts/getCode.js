const ethers = require("ethers");

const provider = new ethers.providers.JsonRpcProvider(
  "http://192.168.1.108:8544"
);

const main = async () => {
  const tx = await provider.getCode(
    "0xD7054d07E2bD5F0ed91dbD8d44F8a10a56AFe355"
  );

  console.log(tx);
};

main();
