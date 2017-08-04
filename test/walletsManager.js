const Wallet = artifacts.require('./Wallet.sol')
const FakeCoin = artifacts.require("./FakeCoin.sol")
const bytes32 = require('./helpers/bytes32')
const Setup = require('../setup/setup')
const eventsHelper = require('./helpers/eventsHelper')
const ErrorsEnum = require("../common/errors")

contract('Wallets Manager', function(accounts) {
  var owner = accounts[0];
  var owner1 = accounts[1];
  var owner2 = accounts[2];
  var owner3 = accounts[3];
  var owner4 = accounts[4];
  var owner5 = accounts[5];
  var nonOwner = accounts[6];
  var wallet;
  var txId;
  var watcher;
  var coin;
  var unix = Math.round(+new Date()/1000);

  const SYMBOL = 'TIME';
  const SYMBOL2 = 'LHT';
  const NAME = 'Time Token';
  const DESCRIPTION = 'ChronoBank Time Shares';
  const NAME2 = 'Labour-hour Token';
  const DESCRIPTION2 = 'ChronoBank Lht Assets';
  const BASE_UNIT = 2;
  const IS_REISSUABLE = true;
  const IS_NOT_REISSUABLE = false;
  const BALANCE_ETH = 1000;
  const fakeArgs = [0,0,0,0,0,0,0,0];

  before('setup', function(done) {

    Setup.setup(done);

  });

  context("initial tests", function() {

    it("Token and balances initialization should pass.", function () {
      return FakeCoin.deployed().then(function (instance) {
        coin = instance;
        return Wallet.new([owner1], 2, Setup.contractsManager.address, "Wallet1").then(function (instance) {
          wallet = instance;
          return Setup.erc20Manager.addToken(coin.address, 'TOKEN', 'TOKEN', '', 2, bytes32('0x0'), bytes32('0x0'), {
            from: owner,
            gas: 3000000
          }).then(function (tx) {
            return coin.mint(accounts[0], 10000).then(() => {
              return coin.mint(wallet.address, 10000)}).then(() => {
              web3.eth.sendTransaction({to: wallet.address, value: 10000, from: accounts[0]})
              balanceETH = web3.eth.getBalance(wallet.address)
              assert.equal(balanceETH, 10000)
              return coin.balanceOf.call(wallet.address).then((balanceERC20) => {
                assert.equal(balanceERC20, 10000)
              })
            });
          });
        });
      });
    });

  });

  context("CRUD test", function(){

    it("can create new MultiSig Wallet contract", function() {
      return Setup.walletsManager.createWallet.call([owner1,owner2],2, "Wallet").then(function(r1) {
        return Setup.walletsManager.createWallet([owner1,owner2],2, "Wallet", {
          from: owner,
          gas: 3000000
        }).then((tx) => {
          const walletCreatedEvents = eventsHelper.extractEvents(tx, "WalletCreated")
          assert.notEqual(walletCreatedEvents.length, 0);
          const walletAddress = walletCreatedEvents[0].args.wallet;
          return Wallet.at(walletAddress).then(function(instance) {
            return instance.m_required.call().then(function(r2) {
              return instance.m_numOwners.call().then(function(r3) {
                assert.equal(r1, ErrorsEnum.OK);
                assert.equal(r2, 2);
                assert.equal(r3, 3);
                return instance.name.call()
                          .then(name => assert.equal(name, bytes32("Wallet")));
              });
            });
          });
        });
      });
    });

    it("doesn't allow add not owned Multisig Wallet contract", function() {
      return Setup.walletsManager.addWallet.call(wallet.address, {from: owner2,
        gas: 3000000 }).then(function (r) {
        return Setup.walletsManager.addWallet(wallet.address, {
          from: owner2,
          gas: 3000000
        }).then(function (tx) {
          return Setup.walletsManager.getWallets.call({from:owner2}).then(function (r2) {
            assert.equal(r, ErrorsEnum.ERROR_WALLET_CANNOT_ADD_TO_REGISTRY);
            assert.equal(r2.length, 1);
          });
        });
      });
    });

    it("allow add Multisig Wallet contract", function() {
      return Setup.walletsManager.addWallet.call(wallet.address).then(function (r) {
        return Setup.walletsManager.addWallet(wallet.address, {
          from: owner,
          gas: 3000000
        }).then(function (tx) {
          return Setup.walletsManager.getWallets.call().then(function (r2) {
            console.log(r)
            assert.equal(r, ErrorsEnum.OK);
            assert.equal(r2.length, 2);
          });
        });
      });
    });

    it("doesn't allow add same Multisig Wallet contract twice ", function() {
      return Setup.walletsManager.addWallet.call(wallet.address).then(function (r) {
        return Setup.walletsManager.addWallet(wallet.address, {
          from: owner,
          gas: 3000000
        }).then(function (tx) {
          return Setup.walletsManager.getWallets.call().then(function (r2) {
            console.log(r)
            assert.equal(r, ErrorsEnum.ERROR_WALLET_EXISTS);
            assert.equal(r2.length, 2);
          });
        });
      });
    });

    it("doesn't allow add non Multisig Wallet contract", function() {
      return Setup.walletsManager.addWallet.call(Setup.chronoBankAsset.address).then(function(r) {
        console.log(r)
        assert.equal(r, ErrorsEnum.ERROR_WALLET_UNKNOWN)
      })
    })

    it('should be able to multisig send ETH', function() {
      return wallet.transfer.call(owner3, 5000, 'ETH').then(function (r) {
        return wallet.transfer(owner3, 5000, 'ETH').then(function (tx) {
          const confirmationEvents = eventsHelper.extractEvents(tx, "ConfirmationNeeded")
          assert.notEqual(confirmationEvents.length, 0)
          const confirmationHash = confirmationEvents[0].args.operation
          const old_balance = web3.eth.getBalance(owner3)
          return wallet.confirm.call(confirmationHash, {from: owner1}).then(function (r2) {
            return wallet.confirm(confirmationHash, {from: owner1}).then(function () {
              assert.equal(r, 4)
              assert.equal(r2, 1)
              const new_balance = web3.eth.getBalance(owner3)
              assert.isTrue(new_balance.equals(old_balance.add(5000)))
            });
          });
        });
      });
    });

    it("shouldn't be able to multisig send ETH if balance not enough", function() {
      return wallet.transfer.call(owner3, 6000, 'ETH').then(function (r) {
        assert.equal(r,9);
      });
    });

    it("should be able to multisig send ERC20", function() {
      return wallet.transfer.call(owner3,5000,'TOKEN', {from: owner}).then(function(r) {
        return wallet.transfer(owner3,5000,'TOKEN', {from: owner}).then(function(tx) {
          const confirmationEvents = eventsHelper.extractEvents(tx, "ConfirmationNeeded")
          assert.notEqual(confirmationEvents.length, 0)
          const confirmationHash = confirmationEvents[0].args.operation
          return wallet.confirm.call(confirmationHash, {from:owner1}).then(function(r2) {
            return wallet.confirm(confirmationHash, {from:owner1}).then(function() {
              return coin.balanceOf.call(owner3).then(function(r3)
              {
                assert.equal(r, 4)
                assert.equal(r2, 1)
                assert.equal(r3, 5000)
              });
            });
          });
        });
      });
    });

    it("shouldn't be able to multisig send ERC20 if balance no enough", function() {
      return wallet.transfer.call(owner3,6000,'TOKEN', {from: owner}).then(function(r) {
        assert.equal(r,9);
      });
    });

    it("should multisig change owner", function() {
      return wallet.isOwner.call(owner1).then(function(r) {
        assert.isTrue(r)
        return wallet.isOwner.call(owner2).then(function (r) {
          assert.isFalse(r)
          return wallet.changeOwner(owner1, owner2).then(function () {
            return wallet.changeOwner(owner1, owner2, {from:owner1}).then(function () {
              return wallet.isOwner.call(owner1).then(function (r) {
                assert.isFalse(r)
                return wallet.isOwner.call(owner2).then(function (r) {
                  assert.isTrue(r)
                })
              })
            })
          })
        })
      })
    })

    it("should multisig add owner", function() {
      return wallet.isOwner.call(owner1).then(function(r) {
        assert.isFalse(r)
        return wallet.addOwner(owner1).then(function () {
          return wallet.addOwner(owner1, {from:owner2}).then(function () {
            return wallet.isOwner.call(owner1).then(function (r) {
              assert.isTrue(r)
            })
          })
        })
      })
    })

    it("should multisig change requirement", function() {
      return wallet.m_required.call().then(function(r) {
        assert.equal(r,2)
        return wallet.changeRequirement(3).then(function() {
          return wallet.changeRequirement(3,{from:owner1}).then(function() {
            return wallet.m_required.call().then(function (r) {
              assert.equal(r, 3)
            })
          })
        })
      })
    })

    it("should multisig kill and transfer funds", function() {
      return coin.balanceOf.call(wallet.address).then(function (r) {
        const wallet_erc20_balance = r
        const wallet_eth_balance = web3.eth.getBalance(wallet.address)
        const old_balance = web3.eth.getBalance(owner4)
        return wallet.kill(owner4, {from: owner}).then(function () {
          return wallet.kill(owner4, {from: owner1}).then(function () {
            return wallet.kill.call(owner4, {from: owner2}).then(function (r) {
              return wallet.kill(owner4, {from: owner2}).then(function () {
                return coin.balanceOf.call(owner4).then(function (r2) {
                  const new_balance = web3.eth.getBalance(owner4)
                  assert(r, 1)
                  assert.isTrue(new_balance.equals(old_balance.add(wallet_eth_balance)))
                  assert.isTrue(wallet_erc20_balance.equals(r2))
                })
              })
            })
          })
        })
      })
    })

  });
});
