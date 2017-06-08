const FakeCoin = artifacts.require("./FakeCoin.sol")
const FakeCoin2 = artifacts.require("./FakeCoin2.sol")
const ChronoBankAssetProxy = artifacts.require('./ChronoBankAssetProxy.sol')
const Setup = require('../setup/setup')
const Reverter = require('./helpers/reverter')
const bytes32 = require('./helpers/bytes32')
const bytes32fromBase58 = require('./helpers/bytes32fromBase58')
const Require = require("truffle-require")
const Config = require("truffle-config")
const eventsHelper = require('./helpers/eventsHelper')

contract('ERC20 Manager', function(accounts) {
  const owner = accounts[0]
  const owner1 = accounts[1]
  const owner2 = accounts[2]
  const owner3 = accounts[3]
  const owner4 = accounts[4]
  const owner5 = accounts[5]
  const nonOwner = accounts[6]
  let coin
  let coin2

  before('setup', function(done) {
    FakeCoin.deployed().then(function(instance) {
      coin = instance
      return FakeCoin2.deployed()
    }).then(function(instance) {
      coin2 = instance
      Setup.setup(done)
    })
  })

  context("initial tests", function(){

    it("doesn't allow to add non ERC20 compatible token", function() {
      return Setup.erc20Manager.addToken(Setup.vote.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0')).then(assert.fail, () => true)
    });

    it("allows to add ERC20 compatible token", function() {
      return Setup.erc20Manager.addToken.call(Setup.chronoBankAssetProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0')).then(function(r) {
        return Setup.erc20Manager.addToken(Setup.chronoBankAssetProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2,Setup.chronoBankAssetProxy.address);
          });
        });
      });
    });

    it("doesn't allow to add same ERC20 compatible token with another symbol", function() {
      return Setup.erc20Manager.addToken.call(Setup.chronoBankAssetProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0')).then(function(r) {
        return Setup.erc20Manager.addToken(Setup.chronoBankAssetProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,Setup.chronoBankAssetProxy.address);
          });
        });
      });
    });

    it("doesn't allow to add another ERC20 compatible token with same symbol", function() {
      return Setup.erc20Manager.addToken.call(Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0')).then(function(r) {
        return Setup.erc20Manager.addToken(Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("allow to add another ERC20 compatible token with new symbol", function() {
      return Setup.erc20Manager.addToken.call(Setup.chronoBankAssetWithFeeProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0')).then(function(r) {
        return Setup.erc20Manager.addToken(Setup.chronoBankAssetWithFeeProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("can show all ERC20 contracts", function() {
      return Setup.erc20Manager.getTokenAddresses.call().then(function(r) {
        console.log(r);
        assert.equal(r.length,2);
      });
    });

    it("doesn't allow to change registered ERC20 compatible token address to another address with same symbol by non owner", function() {
      return Setup.erc20Manager.setToken.call(Setup.chronoBankAssetWithFeeProxy.address,coin.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'),{from:owner1}).then(function(r) {
        return Setup.erc20Manager.setToken(Setup.chronoBankAssetWithFeeProxy.address,coin.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner1,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,coin.address);
          });
        });
      });
    });

    it("allow to change registered ERC20 compatible token address to another address with same symbol by owner", function() {
      return Setup.erc20Manager.setToken.call(Setup.chronoBankAssetWithFeeProxy.address,coin.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'),{from:owner}).then(function(r) {
        return Setup.erc20Manager.setToken(Setup.chronoBankAssetWithFeeProxy.address,coin.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2,coin.address);
          });
        });
      });
    });

    it("doesn't allow to change registered ERC20 compatible token symbol to another symbol by non owner", function() {
      return Setup.erc20Manager.setToken.call(coin.address,coin.address,'TOKEN3','TOKEN3','',2,bytes32('0x0'),bytes32('0x0'),{from:owner1}).then(function(r) {
        return Setup.erc20Manager.setToken(coin.address,coin.address,'TOKEN3','TOKEN3','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner1,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN3').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,coin.address);
          });
        });
      });
    });

    it("allow to change registered ERC20 compatible token symbol to another symbol by owner", function() {
      return Setup.erc20Manager.setToken.call(coin.address,coin.address,'TOKEN3','TOKEN3','',2,bytes32('0x0'),bytes32('0x0'),{from:owner}).then(function(r) {
        return Setup.erc20Manager.setToken(coin.address,coin.address,'TOKEN3','TOKEN3','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN3').then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2,coin.address);
          });
        });
      });
    });

    it("doesn't allow to change registered ERC20 compatible token andress & symbol to another address & symbol by non owner", function() {
      return Setup.erc20Manager.setToken.call(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'),{from:owner1}).then(function(r) {
        return Setup.erc20Manager.setToken(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner1,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("doesn't allow to change registered ERC20 compatible token andress & symbol to another address & registered symbol by owner", function() {
      return Setup.erc20Manager.setToken.call(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'),{from:owner}).then(function(r) {
        return Setup.erc20Manager.setToken(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN','TOKEN','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,false);
            assert.notEqual(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("allow to change registered ERC20 compatible token andress & symbol to another address & symbol by owner", function() {
      return Setup.erc20Manager.setToken.call(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'),{from:owner}).then(function(r) {
        return Setup.erc20Manager.setToken(coin.address,Setup.chronoBankAssetWithFeeProxy.address,'TOKEN2','TOKEN2','',2,bytes32('0x0'),bytes32('0x0'), {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("doesn't allow to remove registered ERC20 compatible token by addrees by non owner", function() {
      return Setup.erc20Manager.removeToken.call(Setup.chronoBankAssetWithFeeProxy.address,{from:owner1}).then(function(r) {
        return Setup.erc20Manager.removeToken(Setup.chronoBankAssetWithFeeProxy.address, {
          from: owner1,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,false);
            assert.equal(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("allow to remove registered ERC20 compatible token by addrees by owner", function() {
      return Setup.erc20Manager.removeToken.call(Setup.chronoBankAssetWithFeeProxy.address,{from:owner}).then(function(r) {
        return Setup.erc20Manager.removeToken(Setup.chronoBankAssetWithFeeProxy.address, {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN2').then(function(r2) {
            assert.equal(r,true);
            assert.notEqual(r2,Setup.chronoBankAssetWithFeeProxy.address);
          });
        });
      });
    });

    it("doesn't allow to remove registered ERC20 compatible token by symbol by non owner", function() {
      return Setup.erc20Manager.removeTokenBySymbol.call('TOKEN',{from:owner1}).then(function(r) {
        return Setup.erc20Manager.removeTokenBySymbol('TOKEN', {
          from: owner1,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,false);
            assert.equal(r2,Setup.chronoBankAssetProxy.address);
          });
        });
      });
    });

    it("allow to remove registered ERC20 compatible token by symbol by owner", function() {
      return Setup.erc20Manager.removeTokenBySymbol.call('TOKEN',{from:owner}).then(function(r) {
        return Setup.erc20Manager.removeTokenBySymbol('TOKEN', {
          from: owner,
          gas: 3000000
        }).then(function(tx) {
          return Setup.erc20Manager.getTokenAddressBySymbol.call('TOKEN').then(function(r2) {
            assert.equal(r,true);
            assert.notEqual(r2,Setup.chronoBankAssetProxy.address);
          });
        });
      });
    });

    it("shows empty ERC20 contracts list", function() {
      return Setup.erc20Manager.getTokenAddresses.call().then(function(r) {
        console.log(r);
        assert.equal(r.length,0);
      });
    });

  });
});
