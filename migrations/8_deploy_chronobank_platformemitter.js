var ChronoBankPlatformEmitter = artifacts.require("./ChronoBankPlatformEmitter.sol");
const EventsHistory = artifacts.require("./EventsHistory.sol");

module.exports = function(deployer,network) {
    const fakeArgs = [0, 0, 0, 0, 0, 0, 0, 0]

    deployer.deploy(ChronoBankPlatformEmitter)
      .then(() => ChronoBankPlatformEmitter.deployed())
      .then(_chronoBankPlatformEmitter => chronoBankPlatformEmitter = _chronoBankPlatformEmitter)
      .then(() => EventsHistory.deployed())
      .then(_eventsHistory => eventsHistory = _eventsHistory)
      //.then(() => console.log(chronoBankPlatformEmitter.contract))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitTransfer.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitIssue.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRevoke.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitOwnershipChange.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRecovery.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitApprove.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitError.getData.apply(this, fakeArgs).slice(0, 10), chronoBankPlatformEmitter.address))
      .then(() => console.log("[MIGRATION] [8] ChronoBankPlatformEmitter: #done"))
}
