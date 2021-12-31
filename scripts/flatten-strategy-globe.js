const {exec} = require('child_process');

async function main() {
  const platform = "pangolin";
  const names = [
    "png-avax-ampl",
    "png-avax-apein",
    "png-avax-avai",
    "png-avax-cly",
    "png-avax-cook",
    "png-avax-cra",
    "png-avax-craft",
    "png-avax-daie",
    "png-avax-dyp",
    "png-avax-frax",
    "png-avax-gohm",
    "png-avax-hct",
    "png-avax-husky",
    "png-avax-imxa",
    "png-avax-insur",
    "png-avax-jewel",
    "png-avax-joe",
    "png-avax-klo",
    "png-avax-linke",
    "png-avax-maxi",
    "png-avax-mim",
    "png-avax-ooe",
    "png-avax-orbs",
    "png-avax-orca",
    "png-avax-pefi",
    "png-avax-png",
    "png-avax-qi",
    "png-avax-roco",
    "png-avax-snob",
    "png-avax-spell",
    "png-avax-spore",
    "png-avax-teddy",
    "png-avax-time",
    "png-avax-tusd",
    "png-avax-usdce",
    "png-avax-usdte",
    "png-avax-vee",
    "png-avax-walbt",
    "png-avax-wbtce",
    "png-avax-wethe",
    "png-avax-wow",
    "png-avax-xava",
    "png-avax-yak",
    "png-avax-yay",
    "png-tusd-daie",
    "png-usdce-daie",
    "png-usdce-mim",
    "png-usdce-png",
    "png-usdce-usdte",
    "png-usdte-skill",
  ];

  const flatten = name => {
    console.log(`flatten ${name}`);
    console.log(`running: npx hardhat flatten ./contracts/snowglobes/${platform}/snowglobe-${name.toLowerCase()}.sol > ./flat/${platform}/snowglobe-${name.toLowerCase()}.sol`);
    exec(
      `npx hardhat flatten ./contracts/snowglobes/${platform}/snowglobe-${name.toLowerCase()}.sol > ./flat/${platform}/snowglobe-${name.toLowerCase()}.sol`, 
      (error, stdout, stderr) => {
        if (error) {
          console.error( `exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      }
    );
    console.log(`running: npx hardhat flatten ./contracts/strategies/${platform}/strategy-${name.toLowerCase()}.sol > ./flat/${platform}/strategy-${name.toLowerCase()}.sol`);
    exec(
      `npx hardhat flatten ./contracts/strategies/${platform}/strategy-${name.toLowerCase()}.sol > ./flat/${platform}/strategy-${name.toLowerCase()}.sol`, 
      (error, stdout, stderr) => {
        if (error) {
          console.error( `exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      }
    );
  };

  for (const name of names) {
    await flatten(name);
  }
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});