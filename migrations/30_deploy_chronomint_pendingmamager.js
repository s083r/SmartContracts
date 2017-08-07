var PendingManager = artifacts.require("./PendingManager.sol");
const Storage = artifacts.require("./Storage.sol");
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(PendingManager, Storage.address, 'PendingManager')
        .then(() => StorageManager.deployed())
        .then(_storageManager => _storageManager.giveAccess(PendingManager.address, 'PendingManager'))
        .then(() => PendingManager.deployed())
        .then(_manager => manager = _manager)
        .then(() => manager.init(ContractsManager.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(manager.address))
        .then(() => console.log("[MIGRATION] [30] PendingManager: #done"))
}
