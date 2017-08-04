const TimeHolder = artifacts.require("./TimeHolder.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require('./StorageManager.sol');
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    if(network !== 'main') {
      deployer.deploy(TimeHolder,Storage.address,'Deposits')
        .then(() => StorageManager.deployed())
        .then((_storageManager) => _storageManager.giveAccess(TimeHolder.address, 'Deposits'))
        .then(() => TimeHolder.deployed())
        .then(_timeHolder => _timeHolder.init(ContractsManager.address, ChronoBankAssetProxy.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(TimeHolder.address))
        .then(() => console.log("[MIGRATION] [22] TimeHolder: #done"))
    }
}
