var TimeHolder = artifacts.require("./TimeHolder.sol");
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");

module.exports = function(deployer, network) {
    deployer.deploy(TimeHolder)
        .then(() => TimeHolder.deployed())
        .then(_timeHolder => _timeHolder.init(ContractsManager.address, ChronoBankAssetProxy.address))
        .then(() => console.log("[MIGRATION] [22] TimeHolder: #done"))
}
