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
    "mainnet": {
      network_id: 1,
      provider: new HDWalletProvider(getWallet(),'pwd','https://mainnet.chronobank.io/'),
      gas: 4700000
    },
    "ropsten": {
      network_id:3,
      provider: new HDWalletProvider(getWallet(),'pwd','https://ropsten.chronobank.io/'),
      timeout: 0,
      test_timeout: 0,
      before_timeout: 0,
      gas: 3290337
    },
    rinkeby:{
      network_id:4,
      provider: new HDWalletProvider(getWallet(),'pwd','https://rinkeby.chronobank.io/'),
      gas: 4700000
    },
    kovan:{
      network_id:42,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://kovan.chronobank.io/'),
      gas: 4700000
    },
    private: {
      network_id: '456719',
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://private.chronobank.io/'),
      gas: 4700000 
    }
  },
  migrations_directory: './migrations'
}
