var ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankAsset)
}
