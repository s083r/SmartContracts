var ERC20Manager = artifacts.require("./ERC20Manager.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

const ContractType = {
  LOCManager:0,
  PendingManager:1,
  UserManager:2,
  ERC20Manager:3,
  ExchangeManager:4,
  TrackersManager:5,
  Voting:6,
  Rewards:7,
  AssetsManager:8,
  TimeHolder:9,
  CrowdsaleManager:10,
  VotingActor:11
};

module.exports = function(deployer, network) {
    deployer.deploy(ERC20Manager, Storage.address, "ERC20 Manager")
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(ERC20Manager.address, "ERC20 Manager"))
      .then(() => ERC20Manager.deployed())
      .then(_manager => manager = _manager)
      .then(() => ContractsManager.deployed())
      .then((_contractsManager) => _contractsManager.setContractAddress(manager.address, ContractType.ERC20Manager))
      .then(() => manager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(manager.address))
      .then(() => console.log("[MIGRATION] [45] ERC20Manager: #done, redeployed"))
}
