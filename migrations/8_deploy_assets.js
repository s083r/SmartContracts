var ChronoBankPlatformEmitter = artifacts.require("./ChronoBankPlatformEmitter.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankPlatformEmitter)
}
