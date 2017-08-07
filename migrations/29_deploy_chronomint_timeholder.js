const TimeHolder = artifacts.require("./TimeHolder.sol");
const Storage = artifacts.require('./Storage.sol');
const StorageManager = artifacts.require('./StorageManager.sol');
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");
const ERC20Manager = artifacts.require("./ERC20Manager.sol");
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");

module.exports = function(deployer, network) {
    deployer.deploy(TimeHolder,Storage.address,'Deposits')
      .then(() => StorageManager.deployed())
      .then((_storageManager) => _storageManager.giveAccess(TimeHolder.address, 'Deposits'))
      .then(() => {
          if (network == "main") {
             return ERC20Manager.deployed()
                .then(_erc20Manager => _erc20Manager.getTokenBySymbol.call("TIME"))
                .then(_token => _token[0]);
         } else {
             return ChronoBankAssetProxy.address;
         }
      })
      .then(_timeAddress => timeAddress = _timeAddress)
      .then(() => TimeHolder.deployed())
      .then(_timeHolder => timeHolder = _timeHolder)
      .then(() => timeHolder.init(ContractsManager.address, timeAddress))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(TimeHolder.address))
      .then(() => {
          if (network == "main") {
              return timeHolder.setLimit(100000000);
          }
      })
      .then(() => console.log("[MIGRATION] [27] TimeHolder: #done"))
}
