const FakeCoin = artifacts.require("./FakeCoin.sol")
const FakeCoin2 = artifacts.require("./FakeCoin2.sol")
const Exchange = artifacts.require("./Exchange.sol")
const Setup = require('../setup/setup')
const Reverter = require('./helpers/reverter')
const bytes32 = require('./helpers/bytes32')

contract('Exchange Manager', function(accounts) {
  const owner = accounts[0]
  const owner1 = accounts[1]
  const owner2 = accounts[2]
  const owner3 = accounts[3]
  const owner4 = accounts[4]
  const owner5 = accounts[5]
  const nonOwner = accounts[6]
  const SYMBOL = 'TIME'
  let coin
  let coin2
  let exchange


  before('setup', function (done) {
    FakeCoin.deployed().then(function(instance) {
      coin = instance
      return FakeCoin2.deployed()
    }).then(function(instance) {
      coin2 = instance
      return Exchange.deployed()
    }).then(function(instance) {
      exchange = instance
      Setup.setup(done)
    })
  })

  context("initial tests", function () {

    it("allow add TIME Asset", function() {
      return Setup.assetsManager.addAsset.call(Setup.chronoBankAssetProxy.address,'TIME', owner).then(function(r) {
        return Setup.assetsManager.addAsset(Setup.chronoBankAssetProxy.address,'TIME', owner, {
          from: accounts[0],
          gas: 3000000
        }).then(function(tx) {
          return Setup.assetsManager.getAssets.call().then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2.length,1);
          });
        });
      });
    });

    it("allow add LHT Asset", function() {
      return Setup.assetsManager.addAsset.call(Setup.chronoBankAssetWithFeeProxy.address,bytes32('LHT'), Setup.chronoMint.address).then(function(r) {
        return Setup.assetsManager.addAsset(Setup.chronoBankAssetWithFeeProxy.address,bytes32('LHT'), Setup.chronoMint.address, {
          from: accounts[0],
          gas: 3000000
        }).then(function(tx) {
          return Setup.assetsManager.getAssets.call().then(function(r2) {
            assert.equal(r,true);
            assert.equal(r2.length,2);
          });
        });
      });
    });


  })

  context("CRUD interface test", function () {

    it("should allow to create new exchange", function () {
      return Setup.exchangeManager.createExchange.call(SYMBOL, false,{
        from: accounts[0],
        gas: 3000000
      }).then(function (r) {
        return Setup.exchangeManager.createExchange(SYMBOL, false, {
          from: accounts[0],
          gas: 3000000
        }).then(function () {
          console.log(r);
          assert.equal(r, 1);
        });
      });
    });

    it("should allow to add exchange contract", function () {
      return Setup.exchangeManager.addExchange.call(exchange.address, {
        from: accounts[0],
        gas: 3000000
      }).then(function (r) {
        return Setup.exchangeManager.addExchange(exchange.address, {
          from: accounts[0],
          gas: 3000000
        }).then(function () {
          console.log(r);
          assert.equal(r, 2);
        });
      });
    });

    it("shouldn't allow to add exchange contract twice", function () {
      return Setup.exchangeManager.addExchange.call(exchange.address, {
        from: accounts[0],
        gas: 3000000
      }).then(function (r) {
        return Setup.exchangeManager.addExchange(exchange.address, {
          from: accounts[0],
          gas: 3000000
        }).then(function () {
          console.log(r);
          assert.equal(r, 0);
        });
      });
    });

    it("shouldn't add exchange contract if it is not an exchange contract", function () {
      return Setup.exchangeManager.addExchange(coin.address, {
        from: accounts[0],
        gas: 3000000
      }).then(assert.fail, () => true)
    });

    it("shouldn't allow exchange owner to delete exchange contract to nonOwner", function () {
      return Setup.exchangeManager.removeExchange.call(exchange.address, {from: accounts[1]}).then(function (r) {
        assert.equal(r,false);
      });
    });

    it("should allow exchange owner to delete exchange contract to owner", function () {
      return Setup.exchangeManager.removeExchange.call(exchange.address).then(function (r) {
        return Setup.exchangeManager.removeExchange(exchange.address).then(function () {
          assert.equal(r, true);
        });
      });
    });

  });

  context("Security tests", function () {

    it("should allow to add exchange contract", function () {
      return Setup.exchangeManager.addExchange.call(exchange.address, {from: owner1}).then(function (r) {
        return Setup.exchangeManager.addExchange(exchange.address, {from: owner1}).then(function () {
          console.log(r);
          assert.equal(r, 2);
        });
      });
    });

    it("should show acccount[1] as exchange contract owner", function () {
      return Setup.exchangeManager.getExchangeOwners.call(exchange.address).then(function (r) {
        assert.equal(r[0],owner1);
      });
    });

    it("shouldn't allow exchange nonOwner to add owner to exchange contract", function () {
      return Setup.exchangeManager.addExchangeOwner.call(exchange.address,owner).then(function (r) {
        return Setup.exchangeManager.addExchangeOwner(exchange.address, owner).then(function () {
          return Setup.exchangeManager.getExchangeOwners.call(exchange.address).then(function (r2)
          {
            assert.equal(r, false);
            assert.equal(r2.length, 1);
          });
        });
      });
    });

    it("should allow exchange owner to add new owner to exchange", function () {
      return Setup.exchangeManager.addExchangeOwner.call(exchange.address, owner, {from: owner1}).then(function (r) {
        return Setup.exchangeManager.addExchangeOwner(exchange.address, owner, {from: owner1}).then(function () {
          return Setup.exchangeManager.isExchangeOwner.call(exchange.address,owner).then(function (r2) {
            assert.equal(r, true);
            assert.equal(r2, true);
          });
        });
      });
    });

    it("shouldn't allow exchange nonOwner to delete owner of exchange", function () {
      return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner).then(function (r) {
        return Setup.exchangeManager.removeExchangeOwner.call(exchange.address, owner, {from: owner2}).then(function (r2) {
          return Setup.exchangeManager.removeExchangeOwner(exchange.address, owner, {from: owner2}).then(function () {
            return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner).then(function (r3) {
              assert.equal(r, true);
              assert.equal(r2, false);
              assert.equal(r3, true);
            });
          });
        });
      });
    });

    it("should allow exchange owner to delete owner of exchange", function () {
      return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner).then(function (r) {
        return Setup.exchangeManager.removeExchangeOwner.call(exchange.address, owner, {from: owner1}).then(function (r2) {
          return Setup.exchangeManager.removeExchangeOwner(exchange.address, owner, {from: owner1}).then(function () {
            return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner).then(function (r3) {
              assert.equal(r, true);
              assert.equal(r2, true);
              assert.equal(r3, false);
            });
          });
        });
      });
    });

    it("shouldn't allow exchange owner to delete himself from exchange owners", function () {
      return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner1).then(function (r) {
        return Setup.exchangeManager.removeExchangeOwner.call(exchange.address, owner1, {from: owner1}).then(function (r2) {
          return Setup.exchangeManager.removeExchangeOwner(exchange.address, owner1, {from: owner1}).then(function () {
            return Setup.exchangeManager.isExchangeOwner.call(exchange.address, owner1).then(function (r3) {
              assert.equal(r, true);
              assert.equal(r2, false);
              assert.equal(r3, true);
            });
          });
        });
      });
    });

  });


});



