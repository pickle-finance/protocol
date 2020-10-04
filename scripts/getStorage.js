const ethers = require("ethers");

const provider = new ethers.providers.JsonRpcProvider(
  "http://192.168.1.108:8544"
);

const main = async () => {
  let pos = ethers.constants.Zero;
  let one = ethers.constants.One;

  for (;;) {
    const tx = await provider.getStorageAt(
      "0x54D17C4a42dAB5Ec565aBe70a3900F791638469d",
      pos
    );

    console.log(tx, pos.toString());

    pos = pos.add(one);
  }
};

main();
