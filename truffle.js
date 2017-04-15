var bip39 = require("bip39");
var hdkey = require('ethereumjs-wallet/hdkey');
var Wallet = require('ethereumjs-wallet');
var ProviderEngine = require("web3-provider-engine");
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var Web3 = require("web3");
var FilterSubprovider = require('web3-provider-engine/subproviders/filters.js');

var providerUrl = "https://testnet.infura.io";
var engine = new ProviderEngine();
var address;

data = {"version":3,"id":"b4156468-36ae-4638-b513-b68c7047446f","address":"24495670db97f50a404400d7aa155537e2fe09e8","Crypto":{"ciphertext":"e95893b9d882188f8a656154104bb8378e19b57caace48ebf02be2524853a698","cipherparams":{"iv":"3a4bc989122c03e636d58eda7ba3baff"},"cipher":"aes-128-ctr","kdf":"scrypt","kdfparams":{"dklen":32,"salt":"3bda57f017884577a6f644eebdd6ee4f06878bda32a1171dbabab362ff397a89","n":1024,"r":8,"p":1},"mac":"21825331289651c1965447e98e607b0f62d206e233c900f751b6d84f6451a53a"}};
var wallet = Wallet.fromV3(data, 'QWEpoi123', true);
address = "0x" + wallet.getAddress().toString("hex");
engine.addProvider(new FilterSubprovider())
engine.addProvider(new WalletSubprovider(wallet, {}));
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(providerUrl)));
engine.start(); // Required by the provider engine.

module.exports = {
networks: {
    "ropsten": {
      network_id: 3,    // Official ropsten network id
      provider: engine, // Use our custom provider
      from: address     // Use the address we derived
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
      gas: 4700000
    }
  },
  migrations_directory: './migrations'
}
