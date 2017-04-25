var ChronoMint = artifacts.require("./ChronoMint.sol");
var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
var ContractsManager = artifacts.require("./ContractsManager.sol");
var Shareable = artifacts.require("./PendingManager.sol");
var UserStorage = artifacts.require("./UserStorage.sol");
var UserManager = artifacts.require("./UserManager.sol");
var TimeHolder = artifacts.require("./TimeHolder.sol");
var Vote = artifacts.require("./Vote.sol");
module.exports = function(deployer, network) {
    return deployer.deploy(UserStorage).then(function () {
        return deployer.deploy(UserManager).then(function () {
            return deployer.deploy(TimeHolder).then(function () {
                return deployer.deploy(Shareable).then(function () {
                    return deployer.deploy(ChronoMint).then(function () {
                        return deployer.deploy(Vote,ChronoBankAssetProxy.address).then(function () {
                            return deployer.deploy(ContractsManager).then(function () {
                                return UserStorage.deployed().then(function (instance) {
                                    return instance.addOwner(UserManager.address).then(function () {
                                    return ChronoMint.deployed().then(function (instance) {
                                        return instance.init(UserStorage.address, Shareable.address, ContractsManager.address).then(function () {
                                        return ContractsManager.deployed().then(function (instance) {
                                            return instance.init(UserStorage.address, Shareable.address).then(function () {
                                            return Vote.deployed().then(function (instance) {
                                                return instance.init(TimeHolder.address, UserStorage.address, Shareable.address).then(function () {
                                                return Shareable.deployed().then(function (instance) {
                                                    return instance.init(UserStorage.address).then(function () {
                                                    return UserManager.deployed().then(function (instance) {
                                                        return instance.init(UserStorage.address, Shareable.address).then(function () {
//                                                        return TimeHolder.deployed().then(function (instance) {
//                                                            return instance.init(UserStorage.address, ChronoBankAssetProxy.address).then(function () {
//                                                        });
//                                                    });
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
    });
    });
    });
    });
    });
}
