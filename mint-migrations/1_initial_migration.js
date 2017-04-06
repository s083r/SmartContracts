var Migrations = artifacts.require("./Migrations.sol");
const truffleConfig = require('../truffle-config.js');

module.exports = function(deployer,network) {
  console.log(network);
  if(network != 'development');
    web3.personal.unlockAccount(truffleConfig.networks[network].from, truffleConfig.networks[network].password, '0x1000')
  deployer.deploy(Migrations);
};
