var ContractsManager = artifacts.require("./ContractsManager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(ContractsManager,Storage.address,'Contracts Manager')
}
