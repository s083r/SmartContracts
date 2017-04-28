var TimeHolder = artifacts.require("./TimeHolder.sol");
module.exports = function(deployer, network) {
    deployer.deploy(TimeHolder)
}
