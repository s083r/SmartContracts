var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankAssetWithFeeProxy)
}
