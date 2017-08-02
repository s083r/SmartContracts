const Storage = artifacts.require('./Storage.sol');
const StorageInterface = artifacts.require('./StorageInterface.sol');
const StorageManager = artifacts.require('./StorageManager.sol');
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer.deploy(Storage)
      .then(() => deployer.deploy(StorageInterface))
      .then(() => deployer.deploy(StorageManager))
      .then(() => Storage.deployed())
      .then((_storage) => _storage.setManager(StorageManager.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(StorageManager.address))
      .then(() => console.log("[MIGRATION] [12] Storage Contracts: #done"))
}
