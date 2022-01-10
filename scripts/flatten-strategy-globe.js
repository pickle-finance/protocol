const {exec} = require('child_process');

async function main() {
  const platform = "traderJoe";
  const names = [
    "joe-avax-isa",
    "joe-avax-jgn",
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