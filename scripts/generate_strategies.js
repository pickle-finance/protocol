async function main() {
  const pools = [
    {
      name: "PngAvaxQi",
      lp: "0xE530dC2095Ef5653205CF5ea79F8979a7028065c",
      rewards: "0xeD472431e02Ea9EF8cC99B9812c335ac0873bba2",
      token: "0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5"
    },
    {
      name: "PngQiPng",
      lp: "0x50E7e19281a80E3C24a07016eDB87EbA9fe8C6cA",
      rewards: "0x2bD42C357a3e13F18849C67e8dC108Cc8462ae33",
      token: "0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5"
    },
    {
      name: "PngAvaxDyp",
      lp: "0x497070e8b6C55fD283D8B259a6971261E2021C01",
      rewards: "0x29a7F3D1F27637EDA531dC69D989c86Ab95225D8",
      token: "0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17"
    },
    {
      name: "PngDypPng",
      lp: "0x3EB6109CbD142e1b4b0Ef1706D92B64628048062",
      rewards: "0x3A0eF6a586D9C15de30eDF5d34ae00E26b0125cE",
      token: "0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17"
    },
    {
      name: "PngAvaxWalbt",
      lp: "0x4555328746f1b6a9b03de964c90ecd99d75bffbc",
      rewards: "0xa296f9474e77ae21f90afb50713f44cc6916fbb2",
      token: "0x9E037dE681CaFA6E661e6108eD9c2bd1AA567Ecd"
    },
    {
      name: "PngWalbtPng",
      lp: "0x29117b9C78DB238725Df08E40D3507DCAaf67713",
      rewards: "0x393fe4bc29AfbB3786D99f043933c49097449fA1",
      token: "0x9E037dE681CaFA6E661e6108eD9c2bd1AA567Ecd"
    },
  ];

  const generate = pool => {
    const network = pool.name.slice(0,3) === "joe" ? "traderJoe" : "pangolin";
  }

  for (const pool of pools) {
    await generate(pool);
  }
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});