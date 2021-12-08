// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

    const contracts = [
        {
            address: "0xE4543C234D4b0aD6d29317cFE5fEeCAF398f5649",
            args: ["0xd586E7F844cEa2F87f50152665BCbc2C279D8d70","0x294ab3200ef36200db84c4128b7f1b4eec71e38a","0x294ab3200ef36200db84c4128b7f1b4eec71e38a","0xf7b8d9f8a82a7a6dd448398afc5c77744bd6cb85"],
        }
    ];

    for (let item of contracts) {
        await verifyInSnowtrace(item.address, item.args);
    }
}

async function verifyInSnowtrace(_addr, _args) {
    await hre.run("verify:verify", {
        address: _addr,
        constructorArguments: _args,
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });