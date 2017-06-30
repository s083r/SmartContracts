var AssetDonator = artifacts.require("./helpers/AssetDonator.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");

module.exports = function(deployer,network) {
    if(network !== 'main') {
        deployer.deploy(AssetDonator)
          .then(() => AssetDonator.deployed())
          .then(_assetDonator => _assetDonator.init(ContractsManager.address))
          .then(() => console.log("[MIGRATION] [33] AssetDonator: #done"))
    }
}
