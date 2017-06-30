var EventsHistory = artifacts.require("./EventsHistory.sol");
var MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer,network) {
    deployer.deploy(EventsHistory)
        .then(() => deployer.deploy(MultiEventsHistory))
        .then(() => console.log("[MIGRATION] [2] EventsHistory: #done"))        
}
