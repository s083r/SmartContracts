var AssetsManager = artifacts.require("./AssetsManager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(AssetsManager,Storage.address,'Assets Manager')
}
