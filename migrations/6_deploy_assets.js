var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
module.exports = function(deployer,network) {
 deployer.deploy(ChronoBankAssetProxy)
}
