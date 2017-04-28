var UserManager = artifacts.require("./UserManager.sol");
module.exports = function(deployer, network) {
    deployer.deploy(UserManager)
}
