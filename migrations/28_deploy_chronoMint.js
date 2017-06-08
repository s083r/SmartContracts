var ERC20Manager = artifacts.require("./ERC20Manager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(ERC20Manager,Storage.address,'ERC20 Manager')
}
