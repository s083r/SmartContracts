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
 deployer.deploy(ChronoBankPlatformTestable)
 deployer.deploy(FakeCoin)
 deployer.deploy(FakeCoin2)
 deployer.deploy(FakeCoin3)
 deployer.deploy(ManagerMock)
 deployer.deploy(AssetsManagerMock)
 deployer.deploy(KrakenPriceTicker,true)
}
}
