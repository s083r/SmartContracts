var HDWalletProvider = require("truffle-hdwallet-provider");
function getWallet(){
  return "{"version":3,"id":"fbd6db63-8eab-42df-85c3-962840013aeb","address":"4a2d3fc1587494ca2ca9cdeb457cd94be5d96a61","crypto":{"ciphertext":"740fd8586795921cd7f3dbc1233c37913bcfa4a729e2aafe13ac1b4b5b0ce4b2","cipherparams":{"iv":"787217097e731736795194356475c316"},"cipher":"aes-128-ctr","kdf":"scrypt","kdfparams":{"dklen":32,"salt":"1f4887d8342f50a20b08a962d26e4775555aeecd13b1037203b0cefff562e105","n":1024,"r":8,"p":1},"mac":"5865188367e6bdb70ace7460c8ce5f4cff0eec0ee5abf6607ee412e0ec638f27"}}";

};

module.exports = {
networks: {
    "mainnet": {
      network_id: 1,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://mainnet.chronobank.io/'),
      gas: 4700000
    },
    "ropsten": {
      network_id:3,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://ropsten.chronobank.io/'),
      timeout: 0,
      test_timeout: 0,
      before_timeout: 0,
      gas: 3290337
    },
    rinkeby:{
      network_id:4,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://rinkeby.chronobank.io/'),
      gas: 4700000
    },
    kovan:{
      network_id:42,
      provider: new HDWalletProvider(getWallet(),'QWEpoi123','https://kovan.chronobank.io/'),
      gas: 4700000
    },
    private: {
      network_id: '456719', 
      provider: new HDWalletProvider('','https://private.chronobank.io/'),
      gas: 4700000
    }
  },
  migrations_directory: './migrations'
}
