var ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankAssetWithFee)
}
