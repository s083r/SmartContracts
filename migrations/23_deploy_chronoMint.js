const Storage = artifacts.require('./Storage.sol');
var PendingManager = artifacts.require("./PendingManager.sol");
module.exports = function(deployer, network) {
    deployer.deploy(PendingManager,Storage.address,'Pending Manager')
}
