var Rewards = artifacts.require("./Rewards.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");
const TimeHolder = artifacts.require("./TimeHolder.sol");

module.exports = function (deployer, network) {
    deployer.deploy(Rewards, Storage.address, "Rewards")
        .then(() => StorageManager.deployed())
        .then(_storageManager => _storageManager.giveAccess(Rewards.address, "Rewards"))
        .then(() => Rewards.deployed())
        .then(_manager => manager = _manager)
        .then(() => manager.init(ContractsManager.address, 0))
        .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(manager.address))
        .then(() => TimeHolder.deployed())
        .then(_timeHolder => _timeHolder.addListener(manager.address))
        .then(() => console.log("[MIGRATION] [31] Rewards: #done"))
}
