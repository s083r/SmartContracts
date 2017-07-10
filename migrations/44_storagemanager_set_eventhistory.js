const StorageManager = artifacts.require('./StorageManager.sol');
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer
        .then(() => StorageManager.deployed())
        .then((_storageManager) => storageManager = _storageManager)
        .then(() => storageManager.setupEventsHistory(MultiEventsHistory.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(storageManager.address))
        .then(() => console.log("[MIGRATION] [44] Storage manager: #done, set event history"))
}
