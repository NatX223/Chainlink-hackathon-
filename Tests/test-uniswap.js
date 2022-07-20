const BN = require("bn.js");
const { isTypedArray } = require("util/types");
const { contracts_build_directory } = require("../truffle-config");
const Payment = artifacts.require("Payment");

contracts("Payment", (accounts) => {
    const Dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const Whale = "0xb60c61dbb7456f024f9338c739b02be68e3f545c";
    const Aave = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";

    const Amount_In = new BN(10).pow(new BN(18)).mul(new BN(1000)); // for the function that involves having the input amount
    const Amount_Out = new BN(10).pow(new BN(18)).mul(new BN(1000));
    const To = accounts[0];

    it("first test", async () => {
        const payment = await Payment.new();

        await payment.sendTokenPrice(
            Dai,
            Aave,
            Amount_Out,
            To,
            {
                from: Whale
            }
        );
            console.log(`${Amount_Out} was swapped`);
    });

});