var ContractsManager = artifacts.require("./ContractsManager.sol");
module.exports = function(deployer, network) {
    deployer.deploy(ContractsManager)
}
