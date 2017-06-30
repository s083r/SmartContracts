var FakeCoin = artifacts.require("./FakeCoin.sol");
var FakeCoin2 = artifacts.require("./FakeCoin2.sol");
var FakeCoin3 = artifacts.require("./FakeCoin3.sol");
var ManagerMock = artifacts.require("./ManagerMock.sol");
var AssetsManagerMock = artifacts.require("./AssetsManagerMock.sol");
var Stub = artifacts.require("./helpers/Stub.sol");
var ChronoBankPlatformTestable = artifacts.require("./ChronoBankPlatformTestable.sol");
var KrakenPriceTicker = artifacts.require("./KrakenPriceTicker.sol");

module.exports = function(deployer,network) {
  if(network === 'development') {
      deployer.deploy(Stub)
        .then(() => deployer.deploy(ChronoBankPlatformTestable))
        .then(() => deployer.deploy(FakeCoin))
        .then(() => deployer.deploy(FakeCoin2))
        .then(() => deployer.deploy(FakeCoin3))
        .then(() => deployer.deploy(ManagerMock))
        .then(() => deployer.deploy(AssetsManagerMock))
        .then(() => deployer.deploy(KrakenPriceTicker, true))
        .then(() => console.log("[MIGRATION] [40] Deploy Test contracts: #done"))
    }
}
