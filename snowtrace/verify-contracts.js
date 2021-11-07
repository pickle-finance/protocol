const axios = require('axios').default;

async function main() {
    const snowkey = process.env.SNOWTRACE_KEY;
    const contract = fs.loa
    let addresses = ["0x0Ec726BF3FF6CBf58c9f300d86F5fAd149a52039"];
    for (let item of addresses) {
        await verifyContracts(item, snowkey);
    }

}



async function verifyContracts(item, key) {
    await axios.post("https://api.snowtrace.io/api", {
        apikey: key,                     //A valid API-Key is required        
        module: 'contract',                             //Do not change
        action: 'verifysourcecode',                     //Do not change
        contractaddress: item,   //Contract Address starts with 0x...     
        sourceCode: ,             //Contract Source Code (Flattened if necessary)
        codeformat: "solidity-single-file",             //solidity-single-file (default) or solidity-standard-json-input (for std-input-json-format support
        contractname: "GaugeV2",         //ContractName (if codeformat=solidity-standard-json-input, then enter contractname as ex: erc20.sol:erc20)
        compilerversion: "v0.6.7+commit.b8d736ae",   // see https://snowtrace.io/solcversions for list of support versions
        optimizationUsed: 1, //0 = No Optimization, 1 = Optimization used (applicable when codeformat=solidity-single-file)
        runs: 200,                                      //set to 200 as default unless otherwise  (applicable when codeformat=solidity-single-file)        
        evmversion: "",             //leave blank for compiler default, homestead, tangerineWhistle, spuriousDragon, byzantium, constantinople, petersburg, istanbul (applicable when codeformat=solidity-single-file)
        licenseType: "3",           //Valid codes 1-12 where 1=No License .. 12=Apache 2.0, see https://snowtrace.io/contract-license-types
        constructorArguements: "00000000000000000000000068b8037876385bbd6bbe80babb2511b95da372c4000000000000000000000000c9a51fb9057380494262fd291aed74317332c0a2",

    })
        .then(function (response) {
            // handle success
            console.log(response);
        })
        .catch(function (error) {
            // handle error
            console.log(error);
        })
        .then(function () {
            // always executed
        });
}


function checkVerification(guid, key) {
    let results = new Map();

    axios.post("//api.snowtrace.io/api", {
        apikey: key,
        guid: guid,
        module: "contract",
        action: "checkverifystatus"
    })
        .then(function (response) {
            // handle success
            console.log(response);
            results.set(guid, "OK");
        })
        .catch(function (error) {
            // handle error
            console.log(error);
            results.set(guid, "ERR");
        })
        .then(function () {
            // always executed
        });

    return results
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });