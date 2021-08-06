const {exec} = require('child_process');

async function main() {
  const names = [
    "png-avax-usdte",
    "png-avax-daie"
    // "png-Avax-SushiE", 
    // "png-Avax-LinkE", 
    // "png-Avax-WbtcE", 
    // "png-Avax-EthE", 
    // "png-Avax-YfiE",
    // "png-Avax-UniE",
    // "png-Avax-AaveE",
    // "png-YfiE-Png",
    // "png-UniE-Png",
    // "png-AaveE-Png",
    // "png-UsdtE-Png",
    // "png-DaiE-Png",
    // "png-SushiE-Png",
    // "png-LinkE-Png",
    // "png-WbtcE-Png",
    // "png-EthE-Png"
  ];

  const flatten = name => {
    exec(
      `truffle-flattener ./contracts/snowglobes/pangolin/snowglobe-${name.toLowerCase()}.sol > ./flat/snowglobe-${name.toLowerCase()}.sol`, 
      (error, stdout, stderr) => {
        if (error) {
          console.error( `exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      }
    );
    exec(
      `truffle-flattener ./contracts/strategies/pangolin/strategy-${name.toLowerCase()}.sol > ./flat/strategy-${name.toLowerCase()}.sol`, 
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