var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");

module.exports = function(deployer,network) {
    const TIME_SYMBOL = 'TIME';
    const TIME_NAME = 'Time Token';

    deployer.deploy(ChronoBankAssetProxy)
      .then(() => ChronoBankAssetProxy.deployed())
      .then(_proxy => _proxy.init(ChronoBankPlatform.address, TIME_SYMBOL, TIME_NAME))
      .then(() => console.log("[MIGRATION] [4] ChronoBankAssetProxy: #done"))
}
