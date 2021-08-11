const {exec} = require('child_process');

async function main() {
  const names = [
    "joe-avax-yak"
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