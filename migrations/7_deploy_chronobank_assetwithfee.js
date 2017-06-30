var ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
const ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");

module.exports = function(deployer,network) {
    deployer.deploy(ChronoBankAssetWithFee)
      .then(() => ChronoBankAssetWithFee.deployed())
      .then(_asset => _asset.init(ChronoBankAssetWithFeeProxy.address))
      .then(() => console.log("[MIGRATION] [7] ChronoBankAssetWithFee: #done"))
}
