/* eslint-disable */
async function impersonates(targetAccounts){
  console.log("Impersonating...");
  for(i = 0; i < targetAccounts.length ; i++){
    console.log(targetAccounts[i]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [
        targetAccounts[i]
      ]
    });
  }
}

async function setupCoreProtocol(PickleJar, Strategy, Controller, underlying, governance, strategist, timelock, devfund, treasury) {
  // create controller contract
  const controller = await Controller.new(governance, strategist, timelock, devfund, treasury, {from: governance});

  console.log("Controller deployed: ", controller.address);

  console.log("strategist: ", strategist);
  
  const jar = await PickleJar.new(underlying, governance, timelock, controller.address, {from: governance});

  // deploy vault contract
  console.log("PickleJar deployed: ", jar.address);

  // deploy strategy
  const strategy = await Strategy.new(governance, strategist, controller.address, timelock, {from: governance});

  console.log("Strategy Deployed: ", strategy.address);
  console.log("Strategy want: ", await strategy.want());

  await controller.setJar(await strategy.want(), jar.address, {from: governance});
  await controller.approveStrategy(await strategy.want(), strategy.address, {from: timelock});
  await controller.setStrategy(await strategy.want(), strategy.address, {from: governance});

  return [
    jar,
    strategy
  ];
}

async function depositJar(_farmer, _underlying, _jar, _amount) {
  await _underlying.approve(_jar.address, _amount, {from: _farmer});
  console.log("farmer: ", _farmer);
  console.log("underlying: ", _underlying.address);
  console.log("jar: ", _jar.address);
  await _jar.deposit(_amount, {from: _farmer});
}

module.exports = {
  impersonates,
  setupCoreProtocol,
  depositJar,
};