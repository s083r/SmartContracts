var LOCManager = artifacts.require("./LOCManager.sol");
const Storage = artifacts.require("./Storage.sol");
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(LOCManager, Storage.address, 'LOCs Manager')
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(LOCManager.address, 'LOCs Manager'))
      .then(() => LOCManager.deployed())
      .then(_manager => manager = _manager)
      .then(() => manager.init(ContractsManager.address))
      .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(manager.address))
      .then(() => console.log("[MIGRATION] [24] LOCManager: #done"))
}
