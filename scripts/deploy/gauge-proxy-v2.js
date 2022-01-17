// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {

  // CONSTANTS ///////////////////////////////////////////////////////////
  const gaugeProxyV1ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const iceQueenAddr = "0xB12531a2d758c7a8BF09f44FC88E646E1BF9D375";
  const gaugeProxyV1addr = "0xFc371bA1E7874Ad893408D7B581F3c8471F03D2C";
  const gaugeProxyV2addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
  ////////////////////////////////////////////////////////////////////////

  // INITIALIZE //////////////////////////////////////////////////////////
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const iceQueen = await ethers.getContractAt(
    "contracts/yield-farming/icequeen.sol:IceQueen",
    iceQueenAddr,
    deployer
  );
  iceQueen.connect(deployer);

  // GAUGEPROXY V1 //////////////////////////////////////////////////////////
  console.log('-- Connect to GaugeProxyV1 --');
  const gaugeProxyV1 = new ethers.Contract(gaugeProxyV1addr, gaugeProxyV1ABI, deployer);

  // GAUGEPROXY V2 //////////////////////////////////////////////////////////
  // console.log("-- Deploying GaugeProxyV2 contract --");
  // const GaugeProxyV2 = await hre.ethers.getContractFactory("GaugeProxyV2");
  // const gaugeProxyV2 = await GaugeProxyV2.deploy();
  // await gaugeProxyV2.deployed();
  // console.log(`GaugeProxyV2 deployed at ${gaugeProxyV2.address}`);

  console.log('-- Connect to GaugeProxyV2 --');
  const gaugeProxyV2 = await ethers.getContractAt(
    "contracts/snowcones/gauge-proxy-v2.sol:GaugeProxyV2",
    gaugeProxyV2addr,
    deployer
  );

  
  // console.log("-- Adding mSNOWCONES to iceQueen --");
  // const mSNOWCONESAddr = await gaugeProxyV2.TOKEN();
  // let populatedTx;
  // populatedTx = await iceQueen.populateTransaction.add(
  //   1,
  //   mSNOWCONESAddr,
  //   false,
  //   { gasLimit: 9000000 }
  // );

  // await deployer.sendTransaction(populatedTx);

  // // Test Bad access //////////////////////////////////////////////////
  
  
  
  
  let tokens = await gaugeProxyV1.tokens();
  console.log('got tokens');


  // // const userAddr = "0xdbc195a0ED72c0B059f8906e97a90636d2B6409F";
  // // await hre.network.provider.request({
  // //   method: "hardhat_impersonateAccount",
  // //   params: [userAddr],
  // // });
  // // const userSigner = ethers.provider.getSigner(userAddr);
  // // const gaugeProxyV2FromUser = await ethers.getContractAt(
  // //   "contracts/snowcones/gauge-proxy-v2.sol:GaugeProxyV2",
  // //   gaugeProxyV2.address,
  // //   userSigner
  // // );
  // // console.log("-- impersonated User --");


  // // await gaugeProxyV2FromUser.addGauge(tokens[0]);
  // // console.log('user added Gauge');
  // // await gaugeProxyV2FromUser.deprecateGauge(tokens[0]);
  // // console.log('user deprecaed Gauge');
  // // await gaugeProxyV2FromUser.renewGauge(tokens[0]);
  // // console.log('user renewed Gauge');
  // // let gauge_addr = await gaugeProxyV2.getGauge(tokens[0]);
  // // console.log('gov got gauge addr');
  // // await gaugeProxyV2FromUser.migrateGauge(gauge_addr, tokens[0]);
  // // console.log('user migrated Gauge');

  const deprecated = [ 
    "0xb21b21E4fA802EE4c158d7cf4bD5416B8035c5e0",
    "0x3815f36C3d60d658797958EAD8778f6500be16Df",
    "0xcD651AD29835099334d312a9372418Eb2b70c72F",
    "0xB4Fe95e89ED8894790aA6164f29FaC4B0De94f47",
    "0x763Aa38c837f61DD8429313933Cc47f24E881430",
    "0x3270b685A4a61252C6f30c1eBca9DbE622984e22",
    "0x18807D2e81F4dd7cef1348B70d23257A587e304E",
    "0x234ed7c95Be12b2A0A43fF602e737225C83c2aa1",
    "0x4bD6D4fE5E3bBaa0FfB075EE9F0980FbcC6c0192",
    "0xAD050d11521dd1dD2Cc136A9e979BAA8F6Fab69a",
    "0x3A4b529d887E0d5672dEd31CE0d7a5202FDb43b2",
    "0x86b109380aB2c34B740848b06Bee62C882F01df5",
    "0x586554828eE99811A8ef75029351179949762c26",
    "0x39BE35904f52E83137881C0AC71501Edf0180181",
    "0x00933c16e06b1d15958317C2793BC54394Ae356C",
    "0x3fcFBCB4b368222fCB4d9c314eCA597489FE8605",
    "0x751089F1bf31B13Fa0F0537ae78108088a2253BF",
    "0xdf7F15d05d641dF701D961a38d03028e0a26a42D",
    "0x392c51Ab0AF3017E3e22713353eCF5B9d6fBDE84",
    "0x7987aDB3C789f071FeFC1BEb15Ce6DfDfbc75899",
    "0x8eDd233546730C51a9d3840e954E5581Eb3fDAB1",
    "0xAbD637a6881a2D4bbf279aE484c2447c070f7C73",
    "0xB305856C54efC004955BC51e3D20ceF566C11eEE",
    "0x2f17BAC3E0339C1BFB6E0DD380d65bd2Fc665C75",
    "0xA42BE3dB9aff3aee48167b240bFEE5e1697e1281",
    "0xdE1A11C331a0E45B9BA8FeE04D4B51A745f1e4A4",
    "0xF4072358C1E3d7841BD7AfDE31F61E17E8d99BE7",
    "0xB4db531076494432eaAA4C6fCD59fcc876af2734",
    "0x586554828eE99811A8ef75029351179949762c26",
    "0x621207093D2e65Bf3aC55dD8Bf0351B980A63815",
    "0x00933c16e06b1d15958317C2793BC54394Ae356C",
    "0x751089F1bf31B13Fa0F0537ae78108088a2253BF",
    "0x39BE35904f52E83137881C0AC71501Edf0180181",
    "0x3fcFBCB4b368222fCB4d9c314eCA597489FE8605",
    "0x53B37b9A6631C462d74D65d61e1c056ea9dAa637",
    "0x763Aa38c837f61DD8429313933Cc47f24E881430",
    "0x392c51Ab0AF3017E3e22713353eCF5B9d6fBDE84",
    "0x7987aDB3C789f071FeFC1BEb15Ce6DfDfbc75899",
    "0x8eDd233546730C51a9d3840e954E5581Eb3fDAB1",
    "0xcD651AD29835099334d312a9372418Eb2b70c72F",
    "0x3270b685A4a61252C6f30c1eBca9DbE622984e22",
    "0x14F98349Af847AB472Eb7f7c705Dc4Bee530713B",
    "0x234ed7c95Be12b2A0A43fF602e737225C83c2aa1",
    "0xb21b21E4fA802EE4c158d7cf4bD5416B8035c5e0",
    "0xdf7F15d05d641dF701D961a38d03028e0a26a42D",
    "0xdE1A11C331a0E45B9BA8FeE04D4B51A745f1e4A4",
    "0xA42BE3dB9aff3aee48167b240bFEE5e1697e1281",
    "0x3815f36C3d60d658797958EAD8778f6500be16Df",
    "0x8309C64390F376fD778BDd701d54d1F8DFfe1F39",
    "0x888Ab4CB2279bDB1A81c49451581d7c243AffbEf",
    "0xa39785a4E4CdDa7509751ed152a00f3D37FbFa9F",
    "0x27f8FE86a513bAAF18B59D3dD15218Cc629640Fc",
    "0xAbD637a6881a2D4bbf279aE484c2447c070f7C73",
    "0x962ECf51A169090002CC88B4Bf16e447d2E13100",
    "0xcC757081C972D0326de42875E0DA2c54af523622",
    "0x2f17BAC3E0339C1BFB6E0DD380d65bd2Fc665C75",
    "0x8b2E1802A7E0E0c7e1EaE8A7c636058964e21047",
    "0x585DE92A24057400a7c445c89338c7d6c61dd080",
    "0x39BF214A93EC72e42bC0B9b8C07BE1af6Fe169dA",
    "0x18807D2e81F4dd7cef1348B70d23257A587e304E",
    "0xB4Fe95e89ED8894790aA6164f29FaC4B0De94f47",
    "0x0B2C4f6C54182EDeE30DFF69Be972f9E04888321",
    "0xB305856C54efC004955BC51e3D20ceF566C11eEE",
    "0x3A4b529d887E0d5672dEd31CE0d7a5202FDb43b2",
    "0xAD050d11521dd1dD2Cc136A9e979BAA8F6Fab69a",
    "0x6AB8DAC517c244f53D86a155a14064E86c2dE653",
    "0xF23c55a05C9f24177FFF5934e8192461AeE4f304",
    "0x4bD6D4fE5E3bBaa0FfB075EE9F0980FbcC6c0192",
    "0x68691a1e8eAAE3dFDcC300BbC0d6D3902bA06E8d",
    "0x75312b14Ce830EC078D93Ac8FA667b14BEAC18E6",
    "0x86b109380aB2c34B740848b06Bee62C882F01df5",
    "0x6440365E1c9282F50477b1F00289b3A7218E47Ef",
    "0xFB3ba5884aD5eBD93C7CB095e4cE08B1C365c2ea",
    "0xf5b4Ba166b8b351C0dF92BdD6bf7d46d537185fB",
    "0x5B8eE2c0a4f249e16f26d31636F1ed79df5405f9",
    "0x8406aAF035c2c50239b32D1cb4583916c1F1c094",
    "0xEb1010B9CF8484fcA2650525d477DD002fa889cE",
    "0xd7E8d994e0ac76a8c41496290A11CA212F074851",
    "0x5fb4d08bCBD444fDD5a0545fdB0C86783D186382",
    "0x45981aB8cE749466c1d2022F50e24AbBEE71d15A",
    "0xb3DbF3ff266a604A66dbc1783257377239792828",
    "0x9397A0257631955DBee5404506B363ab276D2315",
    "0x351BA4c9b0F09aA76a8Aba8b1cF924aE98beb790",
    "0xBc00e639a4795D7DfB43179866acB45eE5169fAE",
    "0xf2596c84aCf1c7350dCF6941604DEd359dD506DB",
    "0x2ad520b64e6058654FE6E67bc790221772b63ecE",
    "0xfEC005280ec0870A5dB1924588aE532743CEb90F",
    "0x384bcAEA70Ae79823312327a52e498E55c6730dA",
    "0x92f75Da67c5E647D86A56a5a3D6C9a25e887504A",
    "0x857f9A61C97d175EaE9E0A8bb74CF701d45a18dc",
    "0x04A3B139fcD004b2A4f957135a3f387124982133",
    "0xEC7dA05C3FA5612f708378025fe1C0e1904aFbb5",
    "0x7F8E7a8Bd63A113B202AE905877918Fb9cA13091",
    "0x08D5Cfaf58a10D306937aAa8B0d2eb40466f7461",
    "0x7CC8068AB5FC2D8c843C4b1A6572a1d1E742D7c8",
    "0x56A6e103D860FBb991eF1Afd24250562a292b2a5",
    "0x5cce813cd2bBbA5aEe6fddfFAde1D3976150b860",
    "0x8c06828A1707b0322baaa46e3B0f4D1D55f6c3E6",
    "0x9854F6615f73e533940F90FfE8DB1eAFB424A3c7",
    "0xB91124eCEF333f17354ADD2A8b944C76979fE3EC",
    "0x1BF90bdeb965a76Af56024EF3e70439DEa89bF3f",
    "0xA829397Af2AdD7C6564a74DC072b3D9095581d70",
    "0xB26A7f2bCA1De2E6BFf411D2ce04ca6C3285e0E8",
    "0xe13E1a491eDc640b0591D70390897620f31bbF6E",
    "0x5c52587bD441A6e6916D2C2d32A84735b9Ee4ccD",
    "0xc72901E3dBE5258728B329352fC4742f4966Bc1f",
    "0xfAa4f21A8Ef346370d00F1a7693FdC5D87C3e12a",
    "0xfe19f34873fC2C7ddcB8e392791b97526B4d22e0",
    "0x6941618661205d5AAd2C880A0B123d19615916b0",
    "0x67b2D2579E631512faFbB1534214eA2D3403563B",
    "0x0666B3db2441A50B6a1C1d330d2f36Df18Ad5651",
    "0x7b2525A502800E496D2e656e5b1188723e547012",
    "0x9EC50ee696bB1c6f8f4e2181f61ad687700005cF",
    "0x894E10EAf14Cc5a7fca4670039114139cd5aeabE",
    "0x322094FDB02677E7a993E735826c9E183fc605a6",
    "0x0c33Aa168E0882Bf0B3e4AFfBf139F44d3aC8d7f",
    "0xeEc21abC6daD38A8515a7C3388E5ef962Cd960e6",
    "0xf4a591BeaC3A4D864C3293477bBD3f86880ADa16",
    "0x8FA104f65BDfddEcA211867b77e83949Fc9d8b44",
    "0x37d4b7B04ccfC14d3D660EDca1637417f5cA37f3",
    "0x32d9D114A2F5aC4ce777463e661BFA28C8fE9Eb7",
    "0x5d0F76119f75dB1593E984E02FE85B6C17A25f8F",
    "0xf25f6f5dad18a16033d05c1f2F558119665fDEF4",
    "0x6C915564607d62B007D203c04473152bc090EE93",
    "0xd63359ff51BF1217730ae2C37979242B1a3f7c53",
    "0xfe1A87Cc4a2144f7eBb7d731bE80bF0e4CC6E909",
    "0x3F2b777d055dbD4D0812f3750Ee71190431D3Fc8",
    "0x150Bc67072c2dB7c55D83302B7dA7D930Eed1c3E",
    "0xa3528E975ed30326e4930c8F70b01F9d9608D8b1",
    "0x39259A07C7B21189BF1bC2Bd75967565b3C1F16e",
    "0x2070Bf205a649dE46F92c4f187Ae941a13688850",
    "0x432be17144cc16b1FEfc58952467e7539073519A",
    "0x7F68E4635b4Ee504028D4b54d07681861d063e48",
    "0xD20C684298Da144289776224e5c19D7FeEA6152a",
    "0xD579719d3a58492D803c7d60E3565733a4ba3DEa",
    "0x096bAE6C45b0047eF3F1cf1f1c8a56eF0cd58cdE"
  ];
  
  // v1-v2 HARD MIGRATION //////////////////////////////////////////////////
  
  console.log("-- Adding Tokens --");
  for (let i = 0; i < tokens.length; i++) {
    if (!deprecated.includes(tokens[i])){
      await gaugeProxyV2.addGauge(tokens[i]);
      let gauge = await gaugeProxyV2.getGauge(tokens[i]);
      console.log(`added: gauge ${gauge} for ${tokens[i]}`);
    }
    else {
      let gauge = await gaugeProxyV2.getGauge(tokens[i]);
      if (gauge) {
        console.log(`found: gauge ${gauge} for ${tokens[i]}`);
      }
      
    }
  }
  ////////////////////////////////////////////////////////////////////////
}

  


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });