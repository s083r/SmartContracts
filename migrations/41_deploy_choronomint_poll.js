var VoteActor = artifacts.require("./VoteActor.sol");
var PollManager = artifacts.require("./PollManager.sol");
var PollDetails = artifacts.require("./PollDetails.sol");
const Storage = artifacts.require("./Storage.sol");
const StorageManager = artifacts.require("./StorageManager.sol");
const ContractsManager = artifacts.require("./ContractsManager.sol");
const MultiEventsHistory = artifacts.require("./MultiEventsHistory.sol");
const TimeHolder = artifacts.require("./TimeHolder.sol");

module.exports = function(deployer, network) {
    let voteActor
    let pollManager

    deployer.deploy(VoteActor, Storage.address, 'Vote')
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(VoteActor.address, 'Vote'))
      .then(() => VoteActor.deployed())
      .then(_voteActor => voteActor = _voteActor)
      .then(() => voteActor.init(ContractsManager.address))
      .then(() => voteActor.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(voteActor.address))
      .then(() => TimeHolder.deployed())
      .then(_timeHolder => _timeHolder.addListener(voteActor.address))
      .then(() => console.log("[MIGRATION] [41.1] Vote Actor: #done"))
      .then(() => deployer.deploy(PollManager, Storage.address, 'Vote'))
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(PollManager.address, 'Vote'))
      .then(() => PollManager.deployed())
      .then(_pollManager => pollManager = _pollManager)
      .then(() => pollManager.init(ContractsManager.address))
      .then(() => pollManager.setupEventsHistory(MultiEventsHistory.address))
      .then(() => MultiEventsHistory.deployed())
      .then(_history => _history.authorize(pollManager.address))
      .then(() => console.log("[MIGRATION] [41.2] Poll Manager: #done"))
      .then(() => deployer.deploy(PollDetails, Storage.address, 'Vote'))
      .then(() => StorageManager.deployed())
      .then(_storageManager => _storageManager.giveAccess(PollDetails.address, 'Vote'))
      .then(() => console.log("[MIGRATION] [41.3] Poll Details: #done"))
}
