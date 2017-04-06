const truffleConfig = require('../truffle-config.js');

var ChronoMint = artifacts.require("./ChronoMint.sol");
var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
var ContractsManager = artifacts.require("./ContractsManager.sol");
var Shareable = artifacts.require("./PendingManager.sol");
var UserStorage = artifacts.require("./UserStorage.sol");
var UserManager = artifacts.require("./UserManager.sol");
var TimeHolder = artifacts.require("./TimeHolder.sol");
var Vote = artifacts.require("./Vote.sol");
module.exports = function(deployer, network) {
 console.log(network);
  if(network != 'development');
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, '0x1000')
    return deployer.deploy(UserStorage).then(function () {
        return deployer.deploy(UserManager).then(function () {
            return deployer.deploy(TimeHolder).then(function () {
                return deployer.deploy(Shareable).then(function () {
                    return deployer.deploy(ChronoMint).then(function () {
                        return deployer.deploy(Vote,ChronoBankAssetProxy.address).then(function () {
                            return deployer.deploy(ContractsManager).then(function () {
                                return UserStorage.deployed().then(function (instance) {
                                    instance.addOwner(UserManager.address);
                                    return ChronoMint.deployed().then(function (instance) {
                                        instance.init(UserStorage.address, Shareable.address, ContractsManager.address);
                                        return ContractsManager.deployed().then(function (instance) {
                                            instance.init(UserStorage.address, Shareable.address);
                                            return Vote.deployed().then(function (instance) {
                                                instance.init(TimeHolder.address, UserStorage.address, Shareable.address);
                                                return Shareable.deployed().then(function (instance) {
                                                    instance.init(UserStorage.address);
                                                    return UserManager.deployed().then(function (instance) {
                                                        instance.init(UserStorage.address, Shareable.address);
                                                        return TimeHolder.deployed().then(function (instance) {
                                                            instance.init(UserStorage.address, ChronoBankAssetProxy.address);
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
