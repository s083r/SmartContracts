var ExchangeManager = artifacts.require("./ExchangeManager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(ExchangeManager,Storage.address,'Exchange Manager')
}
