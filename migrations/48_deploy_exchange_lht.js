var ExchangeManager = artifacts.require("./ExchangeManager.sol");

module.exports = function(deployer,network) {
    const LHT_SYMBOL = 'LHT';

    ExchangeManager.deployed()
      .then(_exchangeManager => exchangeManager = _exchangeManager)
      .then(() => exchangeManager.createExchange(LHT_SYMBOL, false))
}
