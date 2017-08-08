//require("babel-register");
var HDWalletProvider = require("truffle-hdwallet-provider");
function getWallet(){
  try{
    return require('fs').readFileSync("./wallet.json", "utf8").trim();
  } catch(err){
    return "";
  }
}

module.exports = {
networks: {
    test: {
     network_id: 424242,
     host: 'localhost',
     port: 8545,
     gas: 4700000
    },
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 4700000
    }
  },
  migrations_directory: './migrations'
}
