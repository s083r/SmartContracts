var bip39 = require("bip39");
var hdkey = require('ethereumjs-wallet/hdkey');
var Wallet = require('ethereumjs-wallet');
var ProviderEngine = require("web3-provider-engine");
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var Web3 = require("web3");

fs = require('fs')

var providerUrl = "https://testnet.infura.io";
var engine = new ProviderEngine();
var address;

fs.readFile('/Users/mikefluff/Downloads/Unknown1.css', 'utf8', function (err,data) {
var wallet = Wallet.fromV3(data, 'QWEpoi123', true);
address = "0x" + wallet.getAddress().toString("hex");
console.log(address);
engine.addProvider(new WalletSubprovider(wallet, {}));
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(providerUrl)));
engine.start(); // Required by the provider engine.
});

module.exports = {
networks: {
    "ropsten": {
      network_id: 3,    // Official ropsten network id
      provider: engine, // Use our custom provider
      from: address     // Use the address we derived
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
