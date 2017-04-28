var Rewards = artifacts.require("./Rewards.sol");
module.exports = function(deployer,network) {
 deployer.deploy(Rewards)
}
