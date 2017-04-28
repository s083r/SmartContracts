var FakeCoin = artifacts.require("./FakeCoin.sol");
var FakeCoin2 = artifacts.require("./FakeCoin2.sol");
var FakeCoin3 = artifacts.require("./FakeCoin3.sol");
var Stub = artifacts.require("./helpers/Stub.sol");
var ChronoBankPlatformTestable = artifacts.require("./ChronoBankPlatformTestable.sol");
module.exports = function(deployer,network) {
if(network === 'development') {
 deployer.deploy(Stub)
 deployer.deploy(ChronoBankPlatformTestable)
 deployer.deploy(FakeCoin)
 deployer.deploy(FakeCoin2)
 deployer.deploy(FakeCoin3)
}
}
