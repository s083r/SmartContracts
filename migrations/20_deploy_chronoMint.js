const Storage = artifacts.require('./Storage.sol');
const StorageInterface = artifacts.require('./StorageInterface.sol');
const ErrorLibrary = artifacts.require("./Errors.sol");

module.exports = function(deployer, network) {
    deployer.deploy(Storage);
    deployer.deploy(StorageInterface);
    deployer.deploy(ErrorLibrary);
}
