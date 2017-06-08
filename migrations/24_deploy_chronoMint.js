var LOCManager = artifacts.require("./LOCManager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(LOCManager,Storage.address,'LOCs Manager')
}
