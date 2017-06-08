const MultiEventsHistory = artifacts.require('./MultiEventsHistory.sol');
module.exports = function(deployer, network) {
    deployer.deploy(MultiEventsHistory)
}
