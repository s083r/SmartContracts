var LOCManager = artifacts.require("./LOCManager.sol");
const Storage = artifacts.require('./Storage.sol');
var ErrorLibrary = artifacts.require("./Errors.sol");
module.exports = function(deployer, network) {
    deployer.deploy(ErrorLibrary)
    .then(() => { return deployer.link(ErrorLibrary, LOCManager) })
    .then(() => { return deployer.deploy(LOCManager,Storage.address,'LOCs Manager') })

}
