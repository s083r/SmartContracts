var Exchange = artifacts.require("./Exchange.sol");

module.exports = function(deployer,network) {
    deployer.deploy(Exchange)
        .then(() => console.log("[MIGRATION] [10] Exchange: #done"))
}
