var UserStorage = artifacts.require("./UserStorage.sol");
module.exports = function(deployer, network) {
    deployer.deploy(UserStorage)
}
