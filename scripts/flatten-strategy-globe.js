const {exec} = require('child_process');

async function main() {
  const names = [
    "joe-avax-shibx",
    "joe-avax-usdce",
    "joe-daie-usdce",
    "png-avax-usdce",
    "png-avax-tusd",
    "png-avax-lyd",
    "png-avax-husky",
    "png-avax-gaj",
    "png-usdce-png",
    "png-tusd-png",
    "png-lyd-png",
    "png-husky-png",
    "png-gaj-png",
  ];

  const flatten = name => {
    console.log(`flatten ${name}`);
    console.log(`running: truffle-flattener ./contracts/snowglobes/${name.slice(0,3) === "joe" ? "traderJoe" : "pangolin"}/snowglobe-${name.toLowerCase()}.sol > ./flat/snowglobe-${name.toLowerCase()}.sol`);
    exec(
      `truffle-flattener ./contracts/snowglobes/${name.slice(0,3) === "joe" ? "traderJoe" : "pangolin"}/snowglobe-${name.toLowerCase()}.sol > ./flat/snowglobe-${name.toLowerCase()}.sol`, 
      (error, stdout, stderr) => {
        if (error) {
          console.error( `exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      }
    );
    console.log(`running: truffle-flattener ./contracts/strategies/${name.slice(0,3) === "joe" ? "traderJoe" : "pangolin"}/strategy-${name.toLowerCase()}.sol > ./flat/strategy-${name.toLowerCase()}.sol`);
    exec(
      `truffle-flattener ./contracts/strategies/${name.slice(0,3) === "joe" ? "traderJoe" : "pangolin"}/strategy-${name.toLowerCase()}.sol > ./flat/strategy-${name.toLowerCase()}.sol`, 
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