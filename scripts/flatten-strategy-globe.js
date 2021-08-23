const {exec} = require('child_process');

async function main() {
  const names = [
    "joe-avax-ethe",
    "joe-avax-wbtce",
    "joe-avax-usdte",
    "joe-avax-linke",
    "joe-usdte-daie",
    "joe-usdte-wbtce",
    "joe-usdte-ethe",
    "joe-usdte-linke"
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