var ERC20Manager = artifacts.require("./ERC20Manager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(ERC20Manager, Storage.address, "ERC20 Manager")
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(ERC20Manager.address, "ERC20 Manager"))
      .then(() => ERC20Manager.deployed())
      .then(_manager => manager = _manager)
      .then(() => manager.init(ContractsManager.address))
      .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(manager.address))
      .then(() => console.log("[MIGRATION] [28] ERC20Manager: #done"))
}
