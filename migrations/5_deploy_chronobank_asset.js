var ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");

module.exports = function(deployer, network) {
    if(network !== 'main') {
      deployer.deploy(ChronoBankAsset)
        .then(() => ChronoBankAsset.deployed())
        .then(_asset => _asset.init(ChronoBankAssetProxy.address))
        .then(() => console.log("[MIGRATION] [5] ChronoBankAsset: #done"))
    }
}
