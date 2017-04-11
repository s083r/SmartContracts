var Migrations = artifacts.require("./Migrations.sol");
const truffleConfig = require('../truffle-config.js');

module.exports = function(deployer,network) {
  console.log(network);
  console.log(truffleConfig.networks[network].from);
  console.log(truffleConfig.networks[network].password);
  if(network != 'development') {
    if(network == 'kovan')
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, '0x3000')
    else
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, 3000)
  }
  deployer.deploy(Migrations);
};
