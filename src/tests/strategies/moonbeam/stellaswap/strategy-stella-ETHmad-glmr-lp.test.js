const { toWei } = require("../../../utils/testHelper");
const { getWantFromWhale } = require("../../../utils/setupHelper");
const { doTestBehaviorBase } = require("../../testBehaviorBase");

describe("StrategyStellaETHmadGLMRLp", () => {
    const want_addr = "0x9d19EDBFd29D2e01537624B25806493dA0d73bBE";
    const whale_addr = "0x3466acc8d2d7064367b837cf6eefac9659d3ad2a";

    before("Get want token", async () => {
        [alice] = await hre.ethers.getSigners();
        await getWantFromWhale(want_addr, toWei(100, 18), alice, whale_addr);
    });

    doTestBehaviorBase("StrategyStellaETHmadGLMRLp", want_addr, true);
});