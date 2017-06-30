var ExchangeManager = artifacts.require("./ExchangeManager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(ExchangeManager, Storage.address, 'Exchange Manager')
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(ExchangeManager.address, 'Exchange Manager'))
      .then(() => ExchangeManager.deployed())
      .then(_manager => manager = _manager)
      .then(() => manager.init(ContractsManager.address))
      .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(manager.address))
      .then(() => console.log("[MIGRATION] [27] ExchangeManager: #done"))
}
