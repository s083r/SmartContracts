const truffleConfig = require('../truffle.js');
var FakeCoin = artifacts.require("./FakeCoin.sol");
var FakeCoin2 = artifacts.require("./FakeCoin2.sol");
var FakeCoin3 = artifacts.require("./FakeCoin3.sol");
var Stub = artifacts.require("./helpers/Stub.sol");
var ChronoBankPlatformTestable = artifacts.require("./ChronoBankPlatformTestable.sol");
var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
var ChronoBankPlatformEmitter = artifacts.require("./ChronoBankPlatformEmitter.sol");
var EventsHistory = artifacts.require("./EventsHistory.sol");
var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
var ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
var ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
var Exchange = artifacts.require("./Exchange.sol");
var Rewards = artifacts.require("./Rewards.sol");
module.exports = function(deployer,network) {
 console.log(network);
  if(network != 'development')
  { if(network == 'kovan')
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, '0x3000')
    else 
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, 3000)
  }  
    return deployer.deploy(EventsHistory).then(function () {
        return deployer.deploy(ChronoBankPlatform).then(function () {
            return deployer.deploy(ChronoBankAsset).then(function () {
                return deployer.deploy(ChronoBankAssetWithFee).then(function () {
                    return deployer.deploy(ChronoBankAssetProxy).then(function () {
                        return deployer.deploy(ChronoBankAssetWithFeeProxy).then(function () {
                        return deployer.deploy(ChronoBankPlatformEmitter).then(function () {
                            return deployer.deploy(Rewards).then(function () {
                                return deployer.deploy(Exchange).then(function () {
				    return deployer.deploy(Stub).then(function () {
                                    return deployer.deploy(ChronoBankPlatformTestable).then(function () {
                                    return deployer.deploy(FakeCoin).then(function () {
                                    return deployer.deploy(FakeCoin2).then(function () {
                                    return deployer.deploy(FakeCoin3).then(function () {
                                });
				});
				});
				});
				});
				});
                             });
                            });
                        });
                    });
                });
            });
        });
    });
}
