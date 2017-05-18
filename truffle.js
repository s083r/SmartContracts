require("babel-register");
var Wallet = require('ethereumjs-wallet');
var FixtureSubprovider = require('web3-provider-engine/subproviders/fixture.js')
var ProviderEngine = require("web3-provider-engine");
var CacheSubprovider = require('web3-provider-engine/subproviders/cache.js')
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var NonceSubprovider = require('web3-provider-engine/subproviders/nonce-tracker.js')
var VmSubprovider = require('web3-provider-engine/subproviders/vm.js')
var RpcSubprovider = require('web3-provider-engine/subproviders/rpc.js')
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var Web3 = require("web3");
var FilterSubprovider = require('web3-provider-engine/subproviders/filters.js');

var providerUrl = "https://testnet.infura.io/PVe9zSjxTKIP3eAuAHFA";
var engine = new ProviderEngine();
var address;

data = {"version":3,"id":"fbd6db63-8eab-42df-85c3-962840013aeb","address":"4a2d3fc1587494ca2ca9cdeb457cd94be5d96a61","crypto":{"ciphertext":"740fd8586795921cd7f3dbc1233c37913bcfa4a729e2aafe13ac1b4b5b0ce4b2","cipherparams":{"iv":"787217097e731736795194356475c316"},"cipher":"aes-128-ctr","kdf":"scrypt","kdfparams":{"dklen":32,"salt":"1f4887d8342f50a20b08a962d26e4775555aeecd13b1037203b0cefff562e105","n":1024,"r":8,"p":1},"mac":"5865188367e6bdb70ace7460c8ce5f4cff0eec0ee5abf6607ee412e0ec638f27"}};
var wallet = Wallet.fromV3(data, 'QWEpoi123', true);
address = "0x" + wallet.getAddress().toString("hex");
console.log(address);

// static results
engine.addProvider(new FixtureSubprovider({
  web3_clientVersion: 'ProviderEngine/v0.0.0/javascript',
  net_listening: true,
  eth_hashrate: '0x00',
  eth_mining: false,
  eth_syncing: true,
}))
engine.addProvider(new CacheSubprovider())
engine.addProvider(new FilterSubprovider())
engine.addProvider(new NonceSubprovider())
engine.addProvider(new VmSubprovider())
engine.addProvider(new WalletSubprovider(wallet, {}));
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(providerUrl)));

engine.start(); // Required by the provider engine.

module.exports = {
networks: {
    "main": {
      network_id: 1,
      provider: engine,
      from: address,
      gas: 3290337
    },
    "ropsten": {
      network_id:3,    // Official ropsten network id
      provider: engine, // Use our custom provider
      from: address,    // Use the address we derived
      timeout: 0,
      test_timeout: 0,
      before_timeout: 0,
      gas: 3290337
    },
    kovan:{
      network_id:42,
      provider: engine, // Use our custom provider
      from: address,     // Use the address we derived
      gas: 4700000
    },
    'staging': {
      network_id: 1337 // custom private network
      // use default rpc settings
    },
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 3290337
    }
  },
  migrations_directory: './migrations'
}
