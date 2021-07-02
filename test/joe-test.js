const { ethers } = require("hardhat");
const chai = require("chai");
const { expect } = chai;


describe("Strategies", function() {
  // let controller;
  // let snowGlobes;
  // let strategies;

  // let controllerAddress;
  // let snowGlobeAddresses;
  // let strategyAddresses;

  // let controllerABI;
  // let snowGlobeABIs;
  // let strategyABIs;

  // let wavaxABIs = 

  this.beforeEach(async () => {
    const signer = "0xc9a51fB9057380494262fd291aED74317332C0a2";
    const wavax = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";

    const owner = await ethers.provider.getSigner(signer);
    // const xSNOBAddress = '0x83952E7ab4aca74ca96217D6F8f7591BEaD6D64E';
    const ERC20abi = [{"type":"event","name":"Approval","inputs":[{"type":"address","name":"src","internalType":"address","indexed":true},{"type":"address","name":"guy","internalType":"address","indexed":true},{"type":"uint256","name":"wad","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Deposit","inputs":[{"type":"address","name":"dst","internalType":"address","indexed":true},{"type":"uint256","name":"wad","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Transfer","inputs":[{"type":"address","name":"src","internalType":"address","indexed":true},{"type":"address","name":"dst","internalType":"address","indexed":true},{"type":"uint256","name":"wad","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Withdrawal","inputs":[{"type":"address","name":"src","internalType":"address","indexed":true},{"type":"uint256","name":"wad","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"fallback","stateMutability":"payable","payable":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"allowance","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approve","inputs":[{"type":"address","name":"guy","internalType":"address"},{"type":"uint256","name":"wad","internalType":"uint256"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[{"type":"address","name":"","internalType":"address"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint8","name":"","internalType":"uint8"}],"name":"decimals","inputs":[],"constant":true},{"type":"function","stateMutability":"payable","payable":true,"outputs":[],"name":"deposit","inputs":[],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"string","name":"","internalType":"string"}],"name":"name","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"string","name":"","internalType":"string"}],"name":"symbol","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalSupply","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transfer","inputs":[{"type":"address","name":"dst","internalType":"address"},{"type":"uint256","name":"wad","internalType":"uint256"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transferFrom","inputs":[{"type":"address","name":"src","internalType":"address"},{"type":"address","name":"dst","internalType":"address"},{"type":"uint256","name":"wad","internalType":"uint256"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"withdraw","inputs":[{"type":"uint256","name":"wad","internalType":"uint256"}],"constant":false}];
    let WAVAX = new ethers.Contract(wavax, ERC20abi, owner);
    let _wavax = await WAVAX['balanceOf(address)'](owner.address);
    console.log("_wavax: ",_wavax);

    // await hre.network.provider.request({
    //   method: "hardhat_impersonateAccount",
    //   params: [signer]}
    // );

    // const _avax = await ethers.provider.

    // const owner = await ethers.provider.getSigner(signer);

    // controllerAddress = "0xf7b8d9f8a82a7a6dd448398afc5c77744bd6cb85";

    // snowGlobeAddresses = {
    //   ""
    // }

  });

  // 1. Deploy the strategy to be tested


});