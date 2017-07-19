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
const Shareable = artifacts.require("./PendingManager.sol")
const TimeHolder = artifacts.require('./TimeHolder.sol')
const Rewards = artifacts.require('./Rewards.sol')
const Storage = artifacts.require('./Storage.sol')
const UserManager = artifacts.require("./UserManager.sol")
const MultiEventsHistory = artifacts.require('./MultiEventsHistory.sol')
const ManagerMock = artifacts.require('./ManagerMock.sol')
const ProxyFactory = artifacts.require("./ProxyFactory.sol")
const AssetDonator = artifacts.require('./heplers/AssetDonator.sol')
const VoteActor = artifacts.require("./VoteActor.sol");
const PollManager = artifacts.require("./PollManager.sol");
const PollDetails = artifacts.require("./PollDetails.sol");

const TIME_SYMBOL = 'TIME'
const LHT_SYMBOL = 'LHT'

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
let voteActor
let pollManager
let pollDetails
let multiEventsHistory

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
    console.log('deploy contracts')
    return Promise.all([
      Storage.deployed(),
      UserManager.deployed(),
      ContractsManager.deployed(),
      Shareable.deployed(),
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
      VoteActor.deployed(),
      PollManager.deployed(),
      PollDetails.deployed(),
      TimeHolder.deployed(),
      ChronoBankPlatformEmitter.deployed(),
      EventsHistory.deployed(),
      MultiEventsHistory.deployed()
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
      voteActor,
      pollManager,
      pollDetails,
      timeHolder,
      chronoBankPlatformEmitter,
      eventsHistory,
      multiEventsHistory
    ] = instances
  }).then(() => {
    console.log('assetsManager.addAsset TIME')
    return assetsManager.addAsset(chronoBankAssetProxy.address, TIME_SYMBOL, accounts[0], paramsGas)
  }).then(() => {
    console.log('assetsManager.addAsset LHT')
    return assetsManager.addAsset(chronoBankAssetWithFeeProxy.address, LHT_SYMBOL, chronoMint.address, paramsGas)
  }).then(() => {
      if (AssetDonator.address) {
        console.log('setup asset donator')
        return assetsManager.addAssetOwner(TIME_SYMBOL, AssetDonator.address, paramsGas)
      } else {
        console.log('asset donator is not deployed')
      }
  }).then(() => {
    callback()
  }).catch(function (e) {
    console.log(e)
  })
}

module.exports.setup = setup

module.exports = (callback) => {
  return setup(callback)
}
