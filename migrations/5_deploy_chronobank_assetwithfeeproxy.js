var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");

module.exports = function(deployer,network) {
    const LHT_SYMBOL = 'LHT';
    const LHT_NAME = 'Labour-hour Token';

    deployer.deploy(ChronoBankAssetWithFeeProxy)
      .then(() => ChronoBankAssetWithFeeProxy.deployed())
      .then(_proxy => _proxy.init(ChronoBankPlatform.address, LHT_SYMBOL, LHT_NAME))
      .then(() => console.log("[MIGRATION] [5] ChronoBankAssetWithFeeProxy: #done"))
}
