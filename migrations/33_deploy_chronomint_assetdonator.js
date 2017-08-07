var AssetDonator = artifacts.require("./helpers/AssetDonator.sol");
const AssetsManager = artifacts.require("./AssetsManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");

module.exports = function(deployer,network) {
    const TIME_SYMBOL = 'TIME';

    if(network !== 'main') {
        deployer.deploy(AssetDonator)
          .then(() => AssetDonator.deployed())
          .then(_assetDonator => _assetDonator.init(ContractsManager.address))
          .then(() => AssetsManager.deployed())
          .then(_assetsManager => assetsManager = _assetsManager)
          .then(() => assetsManager.addAssetOwner(TIME_SYMBOL, AssetDonator.address))
          .then(() => console.log("[MIGRATION] [33] AssetDonator: #done"))
    }
}
