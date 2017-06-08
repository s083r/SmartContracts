var UserManager = artifacts.require("./UserManager.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(UserManager,Storage.address,'User Manager');
}
