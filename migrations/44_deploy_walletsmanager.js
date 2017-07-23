const WalletsManager = artifacts.require("./WalletsManager.sol");
const Wallet = artifacts.require("./Wallet.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function (deployer, network) {
    deployer.deploy(WalletsManager, Storage.address, 'Wallets Manager')
        .then(() =>  StorageManager.deployed())
        .then(_storageManager => _storageManager.giveAccess(WalletsManager.address, 'Wallets Manager'))
        .then(() => WalletsManager.deployed())
        .then(_manager => manager = _manager)
        .then(() => manager.init(ContractsManager.address))
        .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
        .then(() => MultiEventsHistory.deployed())
        .then(_history => _history.authorize(manager.address))
        .then(() => console.log("[MIGRATION] [44] WalletsManager: #done"))
}
