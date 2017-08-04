var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");

module.exports = function(deployer,network) {
    if(network !== 'main') {
      const TIME_SYMBOL = 'TIME';
      const TIME_NAME = 'Time Token';
      const TIME_DESCRIPTION = 'ChronoBank Time Shares';

      const BASE_UNIT = 8;
      const IS_REISSUABLE = true;
      const IS_NOT_REISSUABLE = false;

      deployer
        .then(() => ChronoBankPlatform.deployed())
        .then(_platform => platform = _platform)
        .then(() => platform.issueAsset(TIME_SYMBOL, 1000000000000, TIME_NAME, TIME_DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE))
        .then(() => deployer.deploy(ChronoBankAssetProxy))
        .then(() => ChronoBankAssetProxy.deployed())
        .then(_proxy => _proxy.init(ChronoBankPlatform.address, TIME_SYMBOL, TIME_NAME))
        .then(() => console.log("[MIGRATION] [4] ChronoBankAssetProxy: #done"))
    }
}
