var Shareable = artifacts.require("./PendingManager.sol");
module.exports = function(deployer, network) {
    deployer.deploy(Shareable)
}
