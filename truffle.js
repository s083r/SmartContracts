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
    "main": {
      network_id: 1,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://mainnet.infura.io/'),
      gas: 4700000
    },
    "ropsten": {
      network_id:3,    // Official ropsten network id
//      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://ropsten.infura.io/'), // Use our custom provider
      timeout: 0,
      test_timeout: 0,
      before_timeout: 0,
      gas: 3290337
    },
    kovan:{
      network_id:42,
//      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://kovan.infura.io/'), // Use our custom provider
      gas: 4700000
    },
    rinkeby:{
      network_id:4,
//      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://rinkeby.infura.io/'), // Use our custom provider
      gas: 4700000
    },
    'staging': {
      network_id: 1337 // custom private network
      // use default rpc settings
    },
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
