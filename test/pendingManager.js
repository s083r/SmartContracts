const Setup = require('../setup/setup')
const Reverter = require('./helpers/reverter')
const bytes32 = require('./helpers/bytes32')
const bytes32fromBase58 = require('./helpers/bytes32fromBase58')
const Require = require("truffle-require")
const Config = require("truffle-config")
const eventsHelper = require('./helpers/eventsHelper')
const MultiEventsHistory = artifacts.require('./MultiEventsHistory.sol')
const PendingManager = artifacts.require("./PendingManager.sol")

contract('Pending Manager', function(accounts) {
  let owner = accounts[0];
  let owner1 = accounts[1];
  let owner2 = accounts[2];
  let owner3 = accounts[3];
  let owner4 = accounts[4];
  let owner5 = accounts[5];
  let nonOwner = accounts[6];
  let conf_sign;
  let conf_sign2;
  let conf_sign3;
  let txId;
  let watcher;
  let eventor;

  before('setup', function(done) {
    PendingManager.at(MultiEventsHistory.address).then((instance) => {
      eventor = instance;
      Setup.setup(done);
    });
  });

  context("with one CBE key", function(){

    it('should receive the right ContractsManager contract address after init() call', () => {
      return Setup.shareable.getContractsManager.call()
        .then((address) => { console.log(address); assert.equal(address, Setup.contractsManager.address) });
    });

    it("can provide PendingManager address.", function() {
      return Setup.contractsManager.getContractAddressByType.call(Setup.contractTypes.PendingManager).then(function(r) {
        assert.equal(r,Setup.shareable.address);
      });
    });

    it("shows owner as a CBE key.", function() {
      return Setup.chronoMint.isAuthorized.call(owner).then(function(r) {
        assert.isOk(r);
      });
    });

    it("doesn't show owner1 as a CBE key.", function() {
      return Setup.chronoMint.isAuthorized.call(owner1).then(function(r) {
        assert.isNotOk(r);
      });
    });

    it("doesn't allows non CBE key to add another CBE key.", function() {
      return Setup.userManager.addCBE(owner1,0x0,{from:owner1}).then(function() {
        return Setup.userManager.isAuthorized.call(owner1).then(function(r){
          assert.isNotOk(r);
        });
      });
    });

    it("shouldn't allow setRequired signatures 2.", function() {
      return Setup.userManager.setRequired(2).then(function() {
        return Setup.userManager.required.call({from: owner}).then(function(r) {
          console.log(r);
          assert.equal(r, 0);
        });
      });
    });

    it("allows one CBE key to add another CBE key.", function() {
      return Setup.userManager.addCBE(owner1,0x0).then(function() {
        return Setup.userManager.isAuthorized.call(owner1).then(function(r){
          assert.isOk(r);
        });
      });
    });

    it("should allow setRequired signatures 2.", function() {
      return Setup.userManager.setRequired(2).then(function() {
        return Setup.userManager.required.call({from: owner}).then(function(r) {
          console.log(r);
          assert.equal(r, 2);
        });
      });
    });

  });

  context("with two CBE keys", function(){

    it("shows owner as a CBE key.", function() {
      return Setup.chronoMint.isAuthorized.call(owner).then(function(r) {
        assert.isOk(r);
      });
    });

    it("shows owner1 as a CBE key.", function() {
      return Setup.chronoMint.isAuthorized.call(owner1).then(function(r) {
        assert.isOk(r);
      });
    });

    it("doesn't show owner2 as a CBE key.", function() {
      return Setup.chronoMint.isAuthorized.call(owner2).then(function(r) {
        assert.isNotOk(r);
      });
    });

    it("pending operation counter should be 0", function() {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("allows to propose pending operation", function() {
      eventsHelper.setupEvents(eventor);
      watcher = eventor.Confirmation();
      return Setup.userManager.addCBE(owner2, 0x0, {from:owner}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events);
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
          assert.equal(r,1);
        });
      });
    });

    it("allows to revoke last confirmation and remove pending operation", function() {
      return Setup.shareable.revoke(conf_sign, {from:owner}).then(function() {
        Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
          assert.equal(r,0);
        });
      });
    });

    it("allows one CBE key to add another CBE key", function() {
      return Setup.userManager.addCBE(owner2, 0x0, {from:owner}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign, {from:owner1}).then(function() {
          return Setup.chronoMint.isAuthorized.call(owner2).then(function(r){
            assert.isOk(r);
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow setRequired signatures 3.", function() {
      return Setup.userManager.setRequired(3).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return Setup.userManager.required.call({from: owner}).then(function(r) {
            assert.equal(r, 3);
          });
        });
      });
    });

  });

  context("with three CBE keys", function(){

    it("allows 2 votes for the new key to grant authorization.", function() {
      return Setup.userManager.addCBE(owner3, 0x0, {from: owner2}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign,{from:owner}).then(function() {
          return Setup.shareable.confirm(conf_sign,{from:owner1}).then(function() {
            return Setup.chronoMint.isAuthorized.call(owner3).then(function(r){
              assert.isOk(r);
            });
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow set required signers to be 4", function() {
      return Setup.userManager.setRequired(4).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return Setup.shareable.confirm(conf_sign,{from:owner2}).then(function() {
            return Setup.userManager.required.call({from: owner}).then(function(r) {
              assert.equal(r, 4);
            });
          });
        });
      });
    });

  });

  context("with four CBE keys", function(){

    it("allows 3 votes for the new key to grant authorization.", function() {
      return Setup.userManager.addCBE(owner4, 0x0, {from: owner3}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign,{from:owner}).then(function() {
          return Setup.shareable.confirm(conf_sign,{from:owner1}).then(function() {
            return Setup.shareable.confirm(conf_sign,{from:owner2}).then(function() {
              return Setup.chronoMint.isAuthorized.call(owner3).then(function(r){
                assert.isOk(r);
              });
            });
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow set required signers to be 5", function() {
      return Setup.userManager.setRequired(5).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return Setup.shareable.confirm(conf_sign,{from:owner2}).then(function() {
            return Setup.shareable.confirm(conf_sign,{from:owner3}).then(function() {
              return Setup.userManager.required.call({from: owner}).then(function(r2) {
                assert.equal(r2, 5);
              });
            });
          });
        });
      });
    });

  });

  context("with five CBE keys", function() {
    it("collects 4 vote to addCBE and granting auth.", function () {
      return Setup.userManager.addCBE(owner5, 0x0, {from: owner4}).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign, {from: owner}).then(function () {
          return Setup.shareable.confirm(conf_sign, {from: owner1}).then(function () {
            return Setup.shareable.confirm(conf_sign, {from: owner2}).then(function () {
              return Setup.shareable.confirm(conf_sign, {from: owner3}).then(function () {
                return Setup.chronoMint.isAuthorized.call(owner5).then(function (r) {
                  assert.isOk(r);
                });
              });
            });
          });
        });
      });
    });

    it("can show all members", function () {
      return Setup.userManager.getCBEMembers.call().then(function (r) {
        assert.equal(r[0][0], owner);
        assert.equal(r[0][1], owner1);
        assert.equal(r[0][2], owner2);
      });
    });

    it("required signers should be 6", function () {
      return Setup.userManager.setRequired(6).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return Setup.shareable.confirm(conf_sign, {from: owner1}).then(function () {
          return Setup.shareable.confirm(conf_sign, {from: owner2}).then(function () {
            return Setup.shareable.confirm(conf_sign, {from: owner3}).then(function () {
              return Setup.shareable.confirm(conf_sign, {from: owner4}).then(function () {
                return Setup.userManager.required.call({from: owner}).then(function (r) {
                  assert.equal(r, 6);
                });
              });
            });
          });
        });
      });
    });


    it("pending operation counter should be 0", function () {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 0);
      });
    });


    it("allows a CBE to propose revocation of an authorized key.", function () {
      return Setup.userManager.revokeCBE(owner5, {from: owner}).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign2 = events[0].args.hash;
        return Setup.userManager.isAuthorized.call(owner5).then(function (r) {
          assert.isOk(r);
        });
      });
    });

    it("check confirmation yet needed should be 5", function () {
      return Setup.shareable.pendingYetNeeded.call(conf_sign2).then(function (r) {
        assert.equal(r, 5);
      });
    });

    it("should increment pending operation counter ", function () {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 1);
      });
    });

    it("allows 5 CBE member vote for the revocation to revoke authorization.", function () {
      return Setup.shareable.confirm(conf_sign2, {from: owner1}).then(function () {
        return Setup.shareable.confirm(conf_sign2, {from: owner2}).then(function () {
          return Setup.shareable.confirm(conf_sign2, {from: owner3}).then(function () {
            return Setup.shareable.confirm(conf_sign2, {from: owner4}).then(function () {
              return Setup.shareable.confirm(conf_sign2, {from: owner5}).then(function () {
                return Setup.chronoMint.isAuthorized.call(owner5).then(function (r) {
                  assert.isNotOk(r);
                });
              });
            });
          });
        });
      });
    });

    it("required signers should be 5", function () {
      return Setup.userManager.required.call({from: owner}).then(function (r) {
        assert.equal(r, 5);
      });
    });

    it("should decrement pending operation counter ", function () {
      return Setup.shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 0);
      });
    });

  });
});
