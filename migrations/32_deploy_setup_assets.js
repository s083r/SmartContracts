const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
const ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
const ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
const AssetsManager = artifacts.require("./AssetsManager.sol");
const Rewards = artifacts.require("./Rewards.sol");
const LOCManager = artifacts.require('./LOCManager.sol');
const Web3 = require("web3");

module.exports = function(deployer,network) {
    const TIME_SYMBOL = 'TIME';
    const LHT_SYMBOL = 'LHT';

    var web3 = new Web3(deployer.provider);

    deployer
      .then(() => Rewards.deployed())
      .then(_rewards => rewards = _rewards)
      .then(() => AssetsManager.deployed())
      .then(_assetsManager => assetsManager = _assetsManager)
      .then(() => ChronoBankPlatform.deployed())
      .then(_chronoBankPlatform => chronoBankPlatform = _chronoBankPlatform)
      .then(() => ChronoBankAssetProxy.deployed())
      .then(_chronoBankAssetProxy => chronoBankAssetProxy = _chronoBankAssetProxy)
      .then(() => ChronoBankAssetWithFeeProxy.deployed())
      .then(_chronoBankAssetWithFeeProxy => chronoBankAssetWithFeeProxy = _chronoBankAssetWithFeeProxy)
      .then(() => ChronoBankAssetWithFee.deployed())
      .then(_chronoBankAssetWithFee => chronoBankAssetWithFee = _chronoBankAssetWithFee)
      .then(() => chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, TIME_SYMBOL))
      .then(() => chronoBankAssetProxy.proposeUpgrade(ChronoBankAsset.address))
      .then(() => chronoBankAssetProxy.transfer(assetsManager.address, 1000000000000))
      .then(() => chronoBankPlatform.changeOwnership(TIME_SYMBOL, assetsManager.address))
      .then(() => chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, LHT_SYMBOL))
      .then(() => chronoBankAssetWithFeeProxy.proposeUpgrade(ChronoBankAssetWithFee.address))
      .then(() => chronoBankAssetWithFee.setupFee(Rewards.address, 100))
      .then(() => chronoBankPlatform.changeOwnership(LHT_SYMBOL, assetsManager.address))
      .then(() => chronoBankPlatform.changeContractOwnership(assetsManager.address))
      .then(() => assetsManager.claimPlatformOwnership())
      .then(() => {
        if (network !== "test") {
          return assetsManager.addAsset(ChronoBankAssetProxy.address, TIME_SYMBOL, web3.eth.accounts[0])
        }
      })
      .then(() => {
        if (network !== "test") {
          return assetsManager.addAsset(chronoBankAssetWithFeeProxy.address, LHT_SYMBOL, LOCManager.address)
        }
      })
      .then(() => console.log("[MIGRATION] [32] Setup Assets: #done"))
}
