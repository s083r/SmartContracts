const ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
const ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
const ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
const ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
const ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
const AssetsManager = artifacts.require("./AssetsManager.sol");
const Rewards = artifacts.require("./Rewards.sol");
const ERC20Manager = artifacts.require("./ERC20Manager.sol");
const LOCManager = artifacts.require('./LOCManager.sol');
const Web3 = require("web3");
const bs58 = require("bs58");
const BigNumber = require("bignumber.js");
const Buffer = require("buffer").Buffer;

module.exports = function(deployer,network) {
    const TIME_SYMBOL = 'TIME';
    const LHT_SYMBOL = 'LHT';

    // https://ipfs.infura.io:5001
    const lhtIconIpfsHash = "Qmdhbz5DTrd3fLHWJ8DY2wyAwhffEZG9MoWMvbm3MRwh8V";

    var web3 = new Web3(deployer.provider);

    deployer
      .then(() => Rewards.deployed())
      .then(_rewards => rewards = _rewards)
      .then(() => AssetsManager.deployed())
      .then(_assetsManager => assetsManager = _assetsManager)
      .then(() => ERC20Manager.deployed())
      .then(_erc20Manager => erc20Manager = _erc20Manager)
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
                  .then(() => erc20Manager.getTokenBySymbol.call(LHT_SYMBOL))
                  .then((asset) => {
                    return erc20Manager.setToken(asset[0], asset[0], asset[1], asset[2], asset[3], asset[4], ipfsHashToBytes32(lhtIconIpfsHash), asset[6])})
                      .then(() => erc20Manager.getTokenBySymbol.call(LHT_SYMBOL))
                      .then((asset) => {
                        if (lhtIconIpfsHash != bytes32ToIPFSHash(asset[5])) {
                            console.error("Error: can't setup LHT icon");
                        }
                  })
        }
      })
      .then(() => console.log("[MIGRATION] [32] Setup Assets: #done"))
}

// Util function
// TODO: @ahiatsevich: copy-paste from
// ChronoBank/ChronoMint/src/utils/Web3Converter.js

function bytes32ToIPFSHash (bytes) {
  if (/^0x0{63}[01]$/.test(`${bytes}`)) {
    return ''
  }
  const str = Buffer.from(bytes.replace(/^0x/, '1220'), 'hex')
  return bs58.encode(str)
}

function ipfsHashToBytes32 (value) {
  return `0x${Buffer.from(bs58.decode(value)).toString('hex').substr(4)}`
}
