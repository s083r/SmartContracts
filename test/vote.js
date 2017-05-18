var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
var ChronoBankPlatformEmitter = artifacts.require("./ChronoBankPlatformEmitter.sol");
var EventsHistory = artifacts.require("./EventsHistory.sol");
var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
var ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
var ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
var Exchange = artifacts.require("./Exchange.sol");
var Rewards = artifacts.require("./Rewards.sol");
var ChronoMint = artifacts.require("./ChronoMint.sol");
var ContractsManager = artifacts.require("./ContractsManager.sol");
var LOC = artifacts.require("./LOC.sol");
var Shareable = artifacts.require("./PendingManager.sol");
var TimeHolder = artifacts.require("./TimeHolder.sol");
var UserStorage = artifacts.require("./UserStorage.sol");
var UserManager = artifacts.require("./UserManager.sol");
var Vote = artifacts.require("./Vote.sol");
var Reverter = require('./helpers/reverter');
var bytes32 = require('./helpers/bytes32');

contract('Vote', function(accounts) {
  var owner = accounts[0];
  var owner1 = accounts[1];
  var owner2 = accounts[2];
  var owner3 = accounts[3];
  var owner4 = accounts[4];
  var owner5 = accounts[5];
  var nonOwner = accounts[6];
  var locController1 = accounts[7];
  var locController2 = accounts[7];
  var conf_sign;
  var conf_sign2;
  var chronoMint;
  var chronoBankPlatform;
  var chronoBankPlatformEmitter;
  var contractsManager;
  var eventsHistory;
  var rewardContract;
  var platform;
  var timeContract;
  var lhContract;
  var timeProxyContract;
  var lhProxyContract;
  var exchange;
  var rewards;
  var userStorage;
  var vote;
  var timeHolder;
  var loc_contracts = [];
  var labor_hour_token_contracts = [];
  var Status = {maintenance:0,active:1, suspended:2, bankrupt:3};
  var unix = Math.round(+new Date()/1000);

  let createPolls = (count) => {
    let data = [];
    for(let i = 0; i < count; i++) {
      data.push(vote.NewPoll([bytes32('1'),bytes32('2')],bytes32('New Poll'),bytes32('New Description'),150, 2, unix + 10000, {from: owner, gas:3000000}).then(() => {
        return vote.activatePoll(i)
      }))
    }
    return Promise.all(data)
  }

  let endPolls = (count) => {
    let data = [];
    for(let i = 0; i < count; i++) {
      data.push(vote.adminEndPoll(i))
    }
    return Promise.all(data)
  }

  let createPollWithActivePolls = (count, active_count) => {
    let data = [];
    for(let i = 0; i < count; i++) {
      data.push(vote.NewPoll([bytes32('1'),bytes32('2')],bytes32('New Poll'),bytes32('New Description'),150, 2, unix + 10000, {from: owner, gas:3000000}).then(() => {
        return vote.activatePoll(i).then(() => {
          return vote.adminEndPoll(i)
        })
      }))
    }
    for(let i =0; i < active_count; i++) {
      data.push(vote.NewPoll([bytes32('1'),bytes32('2')],bytes32('New Poll'),bytes32('New Description'),150, 2, unix + 10000, {from: owner, gas:3000000}));
    }
    return Promise.all(data)
  }

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
    UserStorage.deployed().then(function (instance) {
      return instance.addOwner(UserManager.address)
    }).then(function () {
      return ChronoMint.deployed()
    }).then(function (instance) {
      return instance.init(UserStorage.address, Shareable.address, ContractsManager.address)
    }).then(function () {
      return ContractsManager.deployed()
    }).then(function (instance) {
      return instance.init(UserStorage.address, Shareable.address)
    }).then(function () {
      return Vote.deployed()
    }).then(function (instance) {
      vote = instance;	     
      return instance.init(TimeHolder.address, UserStorage.address, Shareable.address)
    }).then(function () {
      return Shareable.deployed()
    }).then(function (instance) {
      return instance.init(UserStorage.address)
    }).then(function () {
      return UserManager.deployed()
    }).then(function (instance) {
      return instance.init(UserStorage.address, Shareable.address)
    }).then(function () {
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      platform = instance;
      return ChronoBankAsset.deployed()
    }).then(function (instance) {
      timeContract = instance;
      return ChronoBankAssetWithFee.deployed()
    }).then(function (instance) {
      lhContract = instance;
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      timeProxyContract = instance;
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function(instance) {
      lhProxyContract = instance;
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      chronoBankPlatform = instance;
      return ChronoMint.deployed()
    }).then(function (instance) {
      chronoMint = instance;
      return ContractsManager.deployed()
    }).then(function (instance) {
      contractsManager = instance;
      return UserStorage.deployed()
    }).then(function (instance) {
      userStorage = instance;
      return TimeHolder.deployed()
    }).then(function (instance) {
      timeHolder = instance;
      return instance.init(UserStorage.address, ChronoBankAssetProxy.address)
    }).then(function () {
      return timeHolder.addListener(vote.address)
    }).then(function () {
      return ChronoBankPlatformEmitter.deployed()
    }).then(function (instance) {
      chronoBankPlatformEmitter = instance;
      return EventsHistory.deployed()
    }).then(function (instance) {
      eventsHistory = instance;
      return chronoBankPlatform.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitTransfer.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitIssue.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRevoke.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitOwnershipChange.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitApprove.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRecovery.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitError.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addVersion(chronoBankPlatform.address, "Origin", "Initial version.");
    }).then(function () {
      return chronoBankPlatform.issueAsset(SYMBOL, 10000000, NAME, DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(function (r) {
      return chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, SYMBOL, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankPlatform.address, SYMBOL, NAME, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.proposeUpgrade(ChronoBankAsset.address, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAsset.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankAssetProxy.address, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.transfer(ContractsManager.address, 10000000, {from: accounts[0]})
    }).then(function (r) {
      return chronoBankPlatform.changeOwnership(SYMBOL, contractsManager.address, {from: accounts[0]})
    }).then(function (r) {
      return chronoBankPlatform.issueAsset(SYMBOL2, 0, NAME2, DESCRIPTION2, BASE_UNIT, IS_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(function () {
      return chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, SYMBOL2, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankPlatform.address, SYMBOL2, NAME2, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function (instance) {
      return instance.proposeUpgrade(ChronoBankAssetWithFee.address, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFee.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankAssetWithFeeProxy.address, {from: accounts[0]})
    }).then(function () {
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      return instance.changeOwnership(SYMBOL2, ContractsManager.address, {from: accounts[0]})
    }).then(function () {
      return chronoBankPlatform.changeContractOwnership(ContractsManager.address, {from: accounts[0]})
    }).then(function () {
      return contractsManager.claimContractOwnership(ChronoBankPlatform.address, false, {from: accounts[0]})
    }).then(function () {
      return Exchange.deployed()
    }).then(function (instance) {
      exchange = instance;
      return exchange.init(ChronoBankAssetWithFeeProxy.address)
    }).then(function () {
      return exchange.changeContractOwnership(contractsManager.address, {from: accounts[0]})
    }).then(function () {
      return contractsManager.claimContractOwnership(exchange.address, false, {from: accounts[0]})
    }).then(function () {
      return Rewards.deployed()
    }).then(function (instance) {
      rewards = instance;
      return rewards.init(ChronoBankAssetProxy.address, 0)
    }).then(function () {
      return contractsManager.setOtherAddress(rewards.address, {from: accounts[0]})
    }).then(function () {
      return contractsManager.setAddress(ChronoBankAssetProxy.address, {from: accounts[0]})
    }).then(function () {
      return contractsManager.setAddress(ChronoBankAssetWithFeeProxy.address, {from: accounts[0]})
    }).then(function(instance) {
      web3.eth.sendTransaction({to: Exchange.address, value: BALANCE_ETH, from: accounts[0]});
      done();
    }).catch(function (e) { console.log(e); });
  });

  context("before", function() {
    it("Platform has correct TIME proxy address.", function() {
      return platform.proxies.call(SYMBOL).then(function(r) {
        assert.equal(r,timeProxyContract.address);
      });
    });

    it("TIME contract has correct TIME proxy address.", function() {
      return timeContract.proxy.call().then(function(r) {
        assert.equal(r,timeProxyContract.address);
      });
    });

    it("TIME proxy has right version", function() {
      return timeProxyContract.getLatestVersion.call().then(function(r) {
        assert.equal(r,timeContract.address);
      });
    });

    it("shows owner as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner).then(function(r) {
        assert.isOk(r);
      });
    });

    it("check required signers is 1 key.", function() {
      return userStorage.required.call().then(function(r) {
        assert.equal(r,1);
      });
    });

  });

  context("owner shares deposit", function(){

    it("ChronoMint should be able to send 100 TIME to owner", function() {
      return contractsManager.sendAsset.call(1,owner,50000).then(function(r) {
        return contractsManager.sendAsset(1,owner,50000,{from: accounts[0], gas: 3000000}).then(function() {
          assert.isOk(r);
        });
      });
    });

    it("check Owner has 100 TIME", function() {
      return timeProxyContract.balanceOf.call(owner).then(function(r) {
        assert.equal(r,50000);
      });
    });

    it("owner should be able to approve 50 TIME to Vote", function() {
      return timeProxyContract.approve.call(timeHolder.address, 50, {from: accounts[0]}).then((r) => {
        return timeProxyContract.approve(timeHolder.address, 50, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should be able to deposit 50 TIME from owner", function() {
      return timeHolder.deposit.call(50, {from: accounts[0]}).then((r) => {
        return timeHolder.deposit(50, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should show 50 TIME owner balance", function() {
      return timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {
        assert.equal(r,50);
      });
    });

    it("should be able to withdraw 25 TIME from owner", function() {
      return timeHolder.withdrawShares.call(25, {from: accounts[0]}).then((r) => {
        return timeHolder.withdrawShares(25, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should show 25 TIME owner balance", function() {
      return timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {
        assert.equal(r,25);
      });
    });

  });

  context("voting", function(){

    it("should be able to create Poll", function() {
      return vote.getVoteLimit.call().then((r) => {
        console.log(r)
        return vote.NewPoll([bytes32('1'), bytes32('2')], bytes32('New Poll'), bytes32('New Description'), r - 1, 2, unix + 10000, {
          from: owner,
          gas: 3000000
        }).then(() => {
          return vote.pollsCount.call().then((r) => {
            assert.equal(r, 1);
          });
        });
      });
    });

    it("shouldn't be able to create Poll with votelimit exceeded", function() {
      return vote.getVoteLimit.call().then((r) => {
        return vote.NewPoll([bytes32('1'), bytes32('2')], bytes32('New Poll'), bytes32('New Description'), r + 1, 2, unix + 10000, {
          from: owner,
          gas: 3000000
        }).then(assert.fail, () => true)
      })
    })

    it("should be able to activate Poll", function() {
      return vote.activatePoll(0, {from: owner}).then(() => {
        return vote.polls.call(0).then((r) => {
          assert.equal(r[8],true)
        })
      })
    })

    it("should show owner as Poll 0 owner", function() {
      return vote.polls.call(0).then((r) => {
        assert.equal(r[0],owner);
      });
    });

    it("owner1 shouldn't be able to add IPFS hash to Poll", function() {
      return vote.addIpfsHashToPoll(0,bytes32(1234567890), {from: owner1}).then(() => {
        return vote.getIpfsHashesFromPoll.call(0, {from: owner1}).then((r) => {
          assert.notEqual(r[0],bytes32(1234567890));
        });
      });
    });

    it("owner should be able to add IPFS hash to Poll", function() {
      return vote.addIpfsHashToPoll(0,bytes32(1234567890), {from: owner}).then(function() {
        return vote.getIpfsHashesFromPoll.call(0, {from: owner}).then(function(r) {
          assert.equal(r[0],bytes32(1234567890));
        });
      });
    });

    it("should provide IPFS hashes list from Poll by ID", function() {
      return vote.getIpfsHashesFromPoll.call(0, {from: owner}).then((r) => {
        assert.equal(r.length,1);
      });
    });

    it("should be able to show Poll titles", function() {
      return vote.getPollTitles.call({from: owner}).then((r) => {
        assert.equal(r.length,1);
      });
    });

    it("owner should be able to vote Poll 0, Option 1", function() {
      return vote.vote.call(0,1, {from: owner}).then((r) => {
        return vote.vote(0,1, {from: owner}).then((r2) => {
          assert.isOk(r);
        });
      });
    });

    it("owner shouldn't be able to vote Poll 0 twice", function() {
      return vote.vote.call(0,1, {from: owner}).then((r) => {
        return vote.vote.call(0,2, {from: owner}).then((r2) => {
          assert.isNotOk(r);
          assert.isNotOk(r2);
        });
      });
    });

    it("should be able to get Polls list owner took part", function() {
      return vote.getMemberPolls.call({from: owner}).then((r) => {
        assert.equal(r[0].length,1);
      });
    });

    it("should be able to get owner option for Poll", function() {
      return vote.getMemberVotesForPoll.call(0,{from: owner}).then((r) => {
        assert.equal(r,1);
      });
    });

    it("should be able to create another Poll", function() {
      return vote.NewPoll([bytes32('Test Option 1'),bytes32('Test Option 2')],bytes32('New Poll2'),bytes32('New Description2'),75, 2, unix + 1000, {from: owner, gas:3000000}).then((r2) => {
        return vote.pollsCount.call().then((r) => {
          assert.equal(r,2);
        });
      });
    });

    it("should be able to activate Poll 1", function() {
      return vote.activatePoll(1, {from: owner}).then(() => {
        return vote.polls.call(1).then((r) => {
          assert.equal(r[8],true);
        });
      });
    });

    it("should be able to show all options for Poll 0", function() {
      return vote.getOptionsForPoll.call(0).then((r) => {
        assert.equal(r.length,2)
      })
    })

    it("owner should be able to vote Poll 1, Option 1", function() {
      return vote.vote.call(1,1, {from: owner}).then((r) => {
        return vote.vote(1,1, {from: owner}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to get Polls list voter took part", function() {
      return vote.getMemberPolls.call({from: owner}).then((r) => {
        assert.equal(r.length,2)
      })
    })

    it("should be able to show Poll by id", function() {
      return vote.polls.call(0, {from: owner}).then((r) => {
        return vote.polls.call(1, {from: owner}).then((r2) => {
          assert.equal(r[1],bytes32('New Poll'));
          assert.equal(r2[1],bytes32('New Poll2'));
        })
      })
    })

    it("owner1 shouldn't be able to vote Poll 0, Option 1", function() {
      return vote.vote.call(0,1, {from: owner1}).then((r) => {
        assert.isNotOk(r)
      })
    })

  })

  context("owner1 shares deposit and voting", function() {

    it("ChronoMint should be able to send 50 TIME to owner1", function() {
      return contractsManager.sendAsset.call(1,owner1,50).then(function(r) {
        return contractsManager.sendAsset(1,owner1,50,{from: accounts[0], gas: 3000000}).then(function() {
          assert.isOk(r)
        })
      })
    })

    it("check Owner1 has 50 TIME", function() {
      return timeProxyContract.balanceOf.call(owner1).then(function(r) {
        assert.equal(r,50)
      })
    })

    it("owner1 should be able to approve 50 TIME to TimeHolder", function() {
      return timeProxyContract.approve.call(timeHolder.address, 50, {from: owner1}).then((r) => {
        return timeProxyContract.approve(timeHolder.address, 50, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to deposit 50 TIME from owner", function() {
      return timeHolder.deposit.call(50, {from: owner1}).then((r) => {
        return timeHolder.deposit(50, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show 50 TIME owner1 balance", function() {
      return timeHolder.depositBalance.call(owner1, {from: owner1}).then((r) => {
        assert.equal(r,50)
      })
    })

    it("owner1 should be able to vote Poll 0, Option 2", function() {
      return vote.vote.call(0,2, {from: owner1}).then((r) => {
        return vote.vote(0,2, {from: owner1}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("shouldn't show Poll 1 as finished", function() {
      return vote.polls.call(1).then((r) => {
        assert.equal(r[6],true)
      });
    });

    it("owner1 should be able to vote Poll 1, Option 1", function() {
      return vote.vote.call(1,1, {from: owner1}).then((r) => {
        return vote.vote(1,1, {from: owner1}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("should show Poll 1 as finished", function() {
      return vote.polls.call(1).then((r) => {
        assert.equal(r[6],false)
      });
    });

    it("should be able to show number of Votes for each Option for Poll 0", function() {
      return vote.getOptionsVotesForPoll.call(0).then((r) => {
        assert.equal(r[0],25)
        assert.equal(r[1],50)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return vote.getOptionsVotesForPoll.call(1).then((r) => {
        assert.equal(r[0],75)
      })
    })

    it("should be able to get Polls list owner1 took part", function() {
      return vote.getMemberPolls.call({from: owner1}).then((r) => {
        assert.equal(r.length,2);
      })
    })

    it("shouldn't be able to create more then 20 active Polls", function() {
      return createPolls(300).then(() => {
        return vote.getActivePolls.call().then((r) => {
          return vote.getInactivePolls.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 281)
          })
        })
      })
    })

    it("should allow to delete inacvite Polls for CBE admins", function() {
      return vote.removePoll(100).then(() => {
        return vote.getActivePolls.call().then((r) => {
          return vote.getInactivePolls.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 280)
          })
        })
      })
    })

    it("shouldn't allow to delete inacvite Polls for non CBE admins", function() {
      return vote.removePoll(101,{from: owner1}).then(() => {
        return vote.getActivePolls.call().then((r) => {
          return vote.getInactivePolls.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 280)
          })
        })
      })
    })

    it("shouldn't allow to delete acvite Polls for non CBE admins", function() {
      return vote.checkPollIsActive.call(0).then((r) => {
        return vote.removePoll(0).then(() => {
          return vote.getActivePolls.call().then((r2) => {
            return vote.getInactivePolls.call().then((r3) => {
              assert.isOk(r)
              assert.equal(r2, 20)
              assert.equal(r3, 280)
            })
          })
        })
      })
    })

    it("should be able to withdraw 5 TIME from owner1", function() {
      return timeHolder.withdrawShares.call(5, {from: owner1}).then((r) => {
        return timeHolder.withdrawShares(5, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to show number of Votes for each Option for Poll 0", function() {
      return vote.getOptionsVotesForPoll.call(0).then((r) => {
        assert.equal(r[0],25)
        assert.equal(r[1],45)
      })
    })

    it("shouldn't show Poll 0 as finished", function() {
      return vote.polls.call(0).then((r) => {
        assert.equal(r[6],true)
      })
    })

    it("shouldn't show empty list owner1 took part", function() {
      return vote.getMemberPolls.call({from: owner1}).then((r) => {
        assert.equal(r[0].length - r[1].length,2);
      })
    })

    it("should be able to withdraw 45 TIME from owner1", function() {
      return timeHolder.withdrawShares.call(45, {from: owner1}).then((r) => {
        return timeHolder.withdrawShares(45, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show empty list owner1 took part", function() {
      return vote.getMemberPolls.call({from: owner1}).then((r) => {
        assert.equal(r[0].length - r[1],0)
      })
    })

    it("should decrese acvite Polls count", function() {
      return vote.getActivePolls.call().then((r) => {
        assert.equal(r, 20)
      })
    })

    it("owner should be able to approve 50 TIME to Vote", function() {
      return timeProxyContract.approve.call(timeHolder.address, 34975, {from: accounts[0]}).then((r) => {
        return timeProxyContract.approve(timeHolder.address, 34975, {from: accounts[0]}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to deposit 34975 TIME from owner", function() {
      return timeHolder.deposit.call(34975, {from: accounts[0]}).then((r) => {
        return timeHolder.deposit(34975, {from: accounts[0]}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show 50 TIME owner balance", function() {
      return timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {

        assert.equal(r,35000)
      })
    })

    it("should show Poll 0 as finished", function() {
      return vote.polls.call(0).then((r) => {
        assert.equal(r[6],false)
      })
    })

    it("should decrese acvite Polls count", function() {
      return vote.getActivePolls.call().then((r) => {
        assert.equal(r, 19)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 0", function() {
      return vote.getOptionsVotesForPoll.call(0).then((r) => {
        assert.equal(r[0],35000)
        assert.equal(r[1],0)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return vote.getOptionsVotesForPoll.call(1).then((r) => {
        assert.equal(r[0],75)
        assert.equal(r[1],0)
      })
    })

    it("should allow admin to end poll", function() {
      return vote.adminEndPoll(3).then(() => {
        return vote.polls.call(3).then((r) => {
          assert.equal(r[6], false)
        })
      })
    })

    it("should decrese acvite Polls count", function() {
      return vote.getActivePolls.call().then((r) => {
        assert.equal(r, 18)
      })
    })

  })

})

