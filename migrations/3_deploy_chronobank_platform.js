var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");

module.exports = function(deployer,network) {
      deployer.deploy(ChronoBankPlatform)
          .then(() => MultiEventsHistory.deployed())
          .then(_history => history = _history )
          .then(() => ChronoBankPlatform.deployed())
          .then(_platform => platform = _platform)
          .then(() => history.authorize(platform.address))
          .then(() => platform.setupEventsHistory(history.address))
          .then(() => console.log("[MIGRATION] [3] ChronoBankPlatform: #done"))
}
