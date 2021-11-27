
/***
 *======== HOW TO USE THIS FILE ========
 * 
 *  ***/

const { doZapperTests } = require("../zapper-test");

const tests = [
    {
        name: "JoeAvaxJoeLp",
        snowglobeAddress: "0xcC757081C972D0326de42875E0DA2c54af523622",
        gaugeAddress: "0x606E5d9F9d368C2f049431D876C7d1cAb4eD988F",
        controller: "main"
    },
    // {
    //     name: "JoeAvaxSnobLp",
    //     snowglobeAddress: "0x8b2E1802A7E0E0c7e1EaE8A7c636058964e21047",
    //     gaugeAddress: "0xbfb39cf60b4598B1EEc796838faF874f6c41289B",
    //     controller: "main"
    // }
];


for (const test of tests) {
    describe(test.name, async () => {
        doZapperTests(test.name, test.snowglobeAddress, "TraderJoe", test.gaugeAddress, test.controller);
    });
}
