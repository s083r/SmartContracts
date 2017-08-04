var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");

module.exports = function(deployer,network) {
    const LHT_SYMBOL = 'LHT';
    const LHT_NAME = 'Labour-hour Token';
    const LHT_DESCRIPTION = 'ChronoBank Lht Assets';

    const BASE_UNIT = 8;
    const IS_REISSUABLE = true;
    const IS_NOT_REISSUABLE = false;

    deployer
      .then(() => ChronoBankPlatform.deployed())
      .then(_platform => platform = _platform)
      .then(() => platform.issueAsset(LHT_SYMBOL, 0, LHT_NAME, LHT_DESCRIPTION, BASE_UNIT, IS_REISSUABLE))
      .then(() => deployer.deploy(ChronoBankAssetWithFeeProxy))
      .then(() => ChronoBankAssetWithFeeProxy.deployed())
      .then(_proxy => _proxy.init(ChronoBankPlatform.address, LHT_SYMBOL, LHT_NAME))
      .then(() => console.log("[MIGRATION] [6] ChronoBankAssetWithFeeProxy: #done"))
}
