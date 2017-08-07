var Rewards = artifacts.require("./Rewards.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function (deployer, network) {
    deployer.deploy(Rewards, Storage.address, "Deposits")
        .then(() => StorageManager.deployed())
        .then(_storageManager => _storageManager.giveAccess(Rewards.address, "Deposits"))
        .then(() => Rewards.deployed())
        .then(_manager => manager = _manager)
        .then(() => manager.init(ContractsManager.address, 0))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(manager.address))
        .then(() => console.log("[MIGRATION] [26] Rewards: #done"))
}
