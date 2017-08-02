var ContractsManager = artifacts.require("./ContractsManager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require('./StorageManager.sol');
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(ContractsManager, Storage.address, 'ContractsManager')
        .then(() => StorageManager.deployed())
        .then((_storageManager) => storageManager = _storageManager)
        .then(() => storageManager.giveAccess(ContractsManager.address, 'ContractsManager'))
        .then(() => ContractsManager.deployed())
        .then((_contractsManager) => contractsManager = _contractsManager)
        .then(() => contractsManager.addContract(MultiEventsHistory.address, "MultiEventsHistory"))
        .then(() => contractsManager.addContract(StorageManager.address, "StorageManager"))
        .then(() => console.log("[MIGRATION] [20] ContractsManager: #done"))
}
