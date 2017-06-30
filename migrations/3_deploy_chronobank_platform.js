var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
const EventsHistory = artifacts.require("./EventsHistory.sol");

module.exports = function(deployer,network) {
    const TIME_SYMBOL = 'TIME'; // TODO: AG(21-06-2017) copy-paste warn
    const TIME_NAME = 'Time Token';
    const TIME_DESCRIPTION = 'ChronoBank Time Shares';

    const LHT_SYMBOL = 'LHT';
    const LHT_NAME = 'Labour-hour Token';
    const LHT_DESCRIPTION = 'ChronoBank Lht Assets';

    const BASE_UNIT = 8;
    const IS_REISSUABLE = true;
    const IS_NOT_REISSUABLE = false;

    deployer.deploy(ChronoBankPlatform)
        .then(() => EventsHistory.deployed())
        .then(_history => _history.addVersion(ChronoBankPlatform.address, 'Origin', 'Initial version.'))
        .then(() => ChronoBankPlatform.deployed())
        .then(_platform => platform = _platform)
        .then(() => platform.setupEventsHistory(EventsHistory.address))
        .then(() => platform.issueAsset(TIME_SYMBOL, 1000000000000, TIME_NAME, TIME_DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE))
        .then(() => platform.issueAsset(LHT_SYMBOL, 0, LHT_NAME, LHT_DESCRIPTION, BASE_UNIT, IS_REISSUABLE))
        .then(() => platform.issueAsset(LHT_SYMBOL, 0, LHT_NAME, LHT_DESCRIPTION, BASE_UNIT, IS_REISSUABLE))
        .then(() => console.log("[MIGRATION] [3] ChronoBankPlatform: #done"))        
}
