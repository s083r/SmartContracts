var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankPlatform)
}
