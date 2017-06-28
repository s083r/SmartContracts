const Setup = require('../../setup/setup')
const bytes32 = require('./bytes32')
const AssetDonator = artifacts.require('./helpers/AssetDonator.sol')
const AssetsManager = artifacts.require('./helpers/AssetsManager.sol')

contract('AssetDonator', function(accounts) {
  let owner = accounts[0];
  let owner1 = accounts[1];
  let owner2 = accounts[2];
  let owner3 = accounts[3];
  let owner4 = accounts[4];
  let owner5 = accounts[5];
  let nonOwner = accounts[6];
  let assetDonator;

  before('setup', function(done) {
    AssetDonator.deployed()
      .then((_assetDonator) => assetDonator = _assetDonator)
      .then(() => {
          return Setup.setup(function () {
            Setup.assetsManager.addAsset(Setup.chronoBankAssetProxy.address,'TIME', owner, {from: owner,gas: 3000000})
              .then(() => Setup.assetsManager.addAssetOwner(bytes32('TIME'), AssetDonator.address))
              .then((r) => done());
        });
      }
    );
  });

  context("with AssetDonator", function(){
    it("Platform is able to transfer TIMEs for test purposes", function() {
        return assetDonator.sendTime.call({from: owner5}).then(function(r) {
            assert.isTrue(r);
            return assetDonator.sendTime({from: owner5}).then(function(r1) {
                  Setup.chronoBankPlatform.balanceOf.call(owner5, bytes32('TIME')).then(function(r2) {
                      assert.equal(r2, 1000000000);
                  });
            });
      });
    });

    it("Platform is unable to transfer TIMEs twice to the same account", function() {
        return assetDonator.sendTime.call({from: owner5}).then(function(r) {
            assert.isFalse(r);
            return assetDonator.sendTime({from: owner5}).then(function(r1) {
                  Setup.chronoBankPlatform.balanceOf.call(owner5, bytes32('TIME')).then(function(r2) {
                      assert.equal(r2, 1000000000);
                  });
            });
      });
    });
  });
});
