const ChronoBankPlatform = artifacts.require('./ChronoBankPlatform.sol')
const ChronoBankPlatformEmitter = artifacts.require('./ChronoBankPlatformEmitter.sol')
const EventsHistory = artifacts.require('./EventsHistory.sol')
const ChronoBankAssetProxy = artifacts.require('./ChronoBankAssetProxy.sol')
const ChronoBankAssetWithFeeProxy = artifacts.require('./ChronoBankAssetWithFeeProxy.sol')
const ChronoBankAsset = artifacts.require('./ChronoBankAsset.sol')
const ChronoBankAssetWithFee = artifacts.require('./ChronoBankAssetWithFee.sol')
const LOCManager = artifacts.require('./LOCManager.sol')
const ContractsManager = artifacts.require('./ContractsManager.sol')
const Exchange = artifacts.require('./Exchange.sol')
const ERC20Manager = artifacts.require("./ERC20Manager.sol")
const ExchangeManager = artifacts.require("./ExchangeManager.sol")
const AssetsManager = artifacts.require("./AssetsManager")
const PendingManager = artifacts.require("./PendingManager.sol")
const TimeHolder = artifacts.require('./TimeHolder.sol')
const Rewards = artifacts.require('./Rewards.sol')
const Storage = artifacts.require('./Storage.sol')
const UserManager = artifacts.require("./UserManager.sol")
const MultiEventsHistory = artifacts.require('./MultiEventsHistory.sol')
const ProxyFactory = artifacts.require("./ProxyFactory.sol")
const Vote = artifacts.require('./Vote.sol')
const StorageManager = artifacts.require('StorageManager.sol')

const contractTypes = {
  LOCManager: 0, // LOCManager
  PendingManager: 1, // PendingManager
  UserManager: 2, // UserManager
  ERC20Manager: 3, // ERC20Manager
  ExchangeManager: 4, // ExchangeManager
  TrackersManager: 5, // TrackersManager
  Voting: 6, // Voting
  Rewards: 7, // Rewards
  AssetsManager: 8, // AssetsManager
  TimeHolder: 9 //TimeHolder
}

let storage
let assetsManager
let chronoBankPlatform
let chronoMint
let contractsManager
let timeHolder
let shareable
let eventsHistory
let erc20Manager
let chronoBankPlatformEmitter
let rewards
let userManager
let exchangeManager
let chronoBankAsset
let chronoBankAssetProxy
let chronoBankAssetWithFee
let chronoBankAssetWithFeeProxy
let vote
let multiEventsHistory
let storageManager

let accounts
let params
let paramsGas

var getAcc = function () {
  console.log('setup accounts')
  return new Promise(function (resolve, reject) {
    web3.eth.getAccounts((err, acc) => {
      console.log(acc);
      resolve(acc);
    })
  })
}

var exit = function () {
  process.exit()
}

var setup = function (callback) {
  return getAcc().then(r => {
    accounts = r
    params = {from: accounts[0]}
    paramsGas = {from: accounts[0], gas: 3000000}
    console.log('--done')
  }).then(() => {
    console.log('Instantiate the deployed contracts.')
    return Promise.all([
      Storage.deployed(),
      UserManager.deployed(),
      ContractsManager.deployed(),
      PendingManager.deployed(),
      LOCManager.deployed(),
      ChronoBankPlatform.deployed(),
      ChronoBankAsset.deployed(),
      ChronoBankAssetWithFee.deployed(),
      ChronoBankAssetProxy.deployed(),
      ChronoBankAssetWithFeeProxy.deployed(),
      AssetsManager.deployed(),
      ERC20Manager.deployed(),
      ExchangeManager.deployed(),
      Rewards.deployed(),
      Vote.deployed(),
      TimeHolder.deployed(),
      ChronoBankPlatformEmitter.deployed(),
      EventsHistory.deployed(),
      MultiEventsHistory.deployed(),
      StorageManager.deployed()
    ])
  }).then((instances) => {
    [
      storage,
      userManager,
      contractsManager,
      shareable,
      chronoMint,
      chronoBankPlatform,
      chronoBankAsset,
      chronoBankAssetWithFee,
      chronoBankAssetProxy,
      chronoBankAssetWithFeeProxy,
      assetsManager,
      erc20Manager,
      exchangeManager,
      rewards,
      vote,
      timeHolder,
      chronoBankPlatformEmitter,
      eventsHistory,
      multiEventsHistory,
      storageManager
    ] = instances
  }).then(() => {
    module.exports.storage = storage
    module.exports.accounts = accounts
    module.exports.assetsManager = assetsManager
    module.exports.chronoBankPlatform = chronoBankPlatform
    module.exports.chronoMint = chronoMint
    module.exports.contractsManager = contractsManager
    module.exports.timeHolder = timeHolder
    module.exports.shareable = shareable
    module.exports.eventsHistory = eventsHistory
    module.exports.erc20Manager = erc20Manager
    module.exports.chronoBankPlatformEmitter = chronoBankPlatformEmitter
    module.exports.rewards = rewards
    module.exports.userManager = userManager
    module.exports.exchangeManager = exchangeManager
    module.exports.chronoBankAsset = chronoBankAsset
    module.exports.chronoBankAssetProxy = chronoBankAssetProxy
    module.exports.chronoBankAssetWithFee = chronoBankAssetWithFee
    module.exports.chronoBankAssetWithFeeProxy = chronoBankAssetWithFeeProxy
    module.exports.vote = vote
    module.exports.multiEventsHistory = multiEventsHistory
    module.exports.storageManager = storageManager
  }).then(() => {
    callback()
  }).catch(function (e) {
    console.log(e)
    callback(e);
  })
}

module.exports.setup = setup
module.exports.contractTypes = contractTypes
