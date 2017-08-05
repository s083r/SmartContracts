const ExchangeManager = artifacts.require("./ExchangeManager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require('./StorageManager.sol');
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer, network) {
    deployer
        .then(() => ExchangeManager.deployed())
        .then(_manager => manager = _manager)

        .then(() => console.log("  ExchangeManager ", manager.address, "#destroying .."))

        /* reject access to  MultiEventsHistory */

        .then(() => MultiEventsHistory.deployed())
        .then(_history => history = _history)
        .then(() => history.reject(ExchangeManager.address))
        .then(() => history.isAuthorized.call(ExchangeManager.address))
        .then((result) => {
            if (result) {
                console.error("  ExchangeManager is still authorized to emit events");
            } else {
                console.log("  ExchangeManager is not authorized to emit events anymore");
            }
        })

        /* destroy */

        .then(() => manager.destroy())
        .then(() => console.log("  ExchangeManager is destroyed"))

        /* reject access to write in the Storage */

        .then(() => StorageManager.deployed())
        .then(_storageManager => storageManager = _storageManager)
        .then(() => storageManager.blockAccess(manager.address, "Deposits"))
        .then(() => storageManager.isAllowed(manager.address, "Deposits"))
        .then((result) => {
            if (result) {
                console.error("  ExchangeManager is still authorized to write in the storage");
            } else {
                console.log("  ExchangeManager is not authorized to write in the storage anymore");
            }
        })

        /* make sure that destroyed contract is not in services list after destroying */

        .then(() => ContractsManager.deployed())
        .then((_contractsManager) => _contractsManager.isExists.call(manager.address))
        .then((result) => {
            if (result) {
                console.error("  ExchangeManager is still in services list");
            } else {
                console.log("  ExchangeManager is not in services list");
            }
        })
        .then(() => console.log("  Manager: #undeployed"))
        .then(() => deployer.deploy(ExchangeManager, Storage.address,'Deposits'))
        .then(() => StorageManager.deployed())
        .then((_storageManager) => _storageManager.giveAccess(ExchangeManager.address, 'Deposits'))
        .then(() => ExchangeManager.deployed())
        .then(exchangeManager => exchangeManager.init(ContractsManager.address, ChronoBankAssetProxy.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(ExchangeManager.address))
        .then(() => console.log("[MIGRATION] [46] Re-deployment of ExchangeManager: #done ", ExchangeManager.address))
}
