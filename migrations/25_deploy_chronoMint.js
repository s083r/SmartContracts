var Vote = artifacts.require("./Vote.sol");
const Storage = artifacts.require('./Storage.sol');
module.exports = function(deployer, network) {
    deployer.deploy(Vote,Storage.address,'Vote')
}
