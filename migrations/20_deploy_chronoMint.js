const Storage = artifacts.require('./Storage.sol');
const StorageInterface = artifacts.require('./StorageInterface.sol');
module.exports = function(deployer, network) {
    deployer.deploy(Storage);
    deployer.deploy(StorageInterface);
}
