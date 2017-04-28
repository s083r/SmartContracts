var Vote = artifacts.require("./Vote.sol");
module.exports = function(deployer, network) {
    deployer.deploy(Vote)
}
