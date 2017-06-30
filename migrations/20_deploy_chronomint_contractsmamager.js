var ContractsManager = artifacts.require("./ContractsManager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require('./StorageManager.sol');

module.exports = function(deployer, network) {
    deployer.deploy(ContractsManager, Storage.address, 'Contracts Manager')
        .then(() => StorageManager.deployed())
        .then((_storageManager) => _storageManager.giveAccess(ContractsManager.address, 'Contracts Manager'))
        .then(() => ContractsManager.deployed())
        .then((_contractsManager) => _contractsManager.init())
        .then(() => console.log("[MIGRATION] [20] ContractsManager: #done"))
}
