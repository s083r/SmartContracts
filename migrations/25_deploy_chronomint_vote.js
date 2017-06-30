var Vote = artifacts.require("./Vote.sol");
const Storage = artifacts.require("./Storage.sol");
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");
const TimeHolder = artifacts.require("./TimeHolder.sol");

module.exports = function(deployer, network) {
    deployer.deploy(Vote, Storage.address, 'Vote')
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(Vote.address, 'Vote'))
      .then(() => Vote.deployed())
      .then(_manager => manager = _manager)
      .then(() => manager.init(ContractsManager.address))
      .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(manager.address))
      .then(() => TimeHolder.deployed())
      .then(_timeHolder => _timeHolder.addListener(manager.address))
      .then(() => console.log("[MIGRATION] [25] Vote: #done"))
}
