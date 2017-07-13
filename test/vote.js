const Reverter = require('./helpers/reverter')
const bytes32 = require('./helpers/bytes32')
const bytes32fromBase58 = require('./helpers/bytes32fromBase58')
const Q = require("q");
const eventsHelper = require('./helpers/eventsHelper')
const Setup = require('../setup/setup')
const MultiEventsHistory = artifacts.require('./MultiEventsHistory.sol')
const PendingManager = artifacts.require("./PendingManager.sol")
const ErrorsEnum = require("../common/errors");


contract('Vote', function(accounts) {
  const owner = accounts[0];
  const owner1 = accounts[1];
  const owner2 = accounts[2];
  const owner3 = accounts[3];
  const owner4 = accounts[4];
  const owner5 = accounts[5];
  const nonOwner = accounts[6];
  const SYMBOL = 'TIME'
  let unix = Math.round(+new Date()/1000);

  let createPolls = (count) => {
    var chain = Q.when();
    for(var i = 0; i < count; i++) {
	       chain = chain.then(function() {
           return Setup.vote.manager.NewPoll([bytes32('1'),bytes32('2')],[bytes32('1'), bytes32('2')], bytes32('New Poll'),bytes32('New Description'),150, unix + 10000, {from: owner, gas:3000000})
           .then((r) => r.logs[0] ? r.logs[0].args.pollId : 0)
           .then((createdPollId) => Setup.vote.manager.activatePoll(createdPollId, {from: owner}))
	       });
    }

    return Q.all(chain);
  }

  // let endPolls = (count) => {
  //   let data = [];
  //   for(let i = 0; i < count; i++) {
  //     data.push(Setup.vote.adminEndPoll(i))
  //   }
  //   return Promise.all(data)
  // }
  //
  // let createPollWithActivePolls = (count, active_count) => {
  //   let data = [];
  //   for(let i = 0; i < count; i++) {
  //     data.push(Setup.vote.NewPoll([bytes32('1'),bytes32('2')],[bytes32('1'), bytes32('2')],bytes32('New Poll'),bytes32('New Description'),150, unix + 10000, {from: owner, gas:3000000}).then(() => {
  //       return Setup.vote.activatePoll(i).then(() => {
  //         return Setup.vote.adminEndPoll(i)
  //       })
  //     }))
  //   }
  //   for(let i =0; i < active_count; i++) {
  //     data.push(Setup.vote.NewPoll([bytes32('1'),bytes32('2')],[bytes32('1'), bytes32('2')],bytes32('New Poll'),bytes32('New Description'),150, unix + 10000, {from: owner, gas:3000000}));
  //   }
  //   return Promise.all(data)
  // }

  before('setup', function(done) {
    PendingManager.at(MultiEventsHistory.address).then((instance) => {
      eventor = instance;
      Setup.setup(done);
    });
  });

  context("owner shares deposit", function(){

    it("allow add TIME Asset", function() {
      return Setup.assetsManager.addAsset.call(Setup.chronoBankAssetProxy.address,'TIME', owner).then(function(r) {
        console.log(r);
        return Setup.assetsManager.addAsset(Setup.chronoBankAssetProxy.address,'TIME', owner, {
          from: accounts[0],
          gas: 3000000
        }).then(function(tx) {
          console.log(tx);
          return Setup.assetsManager.getAssets.call().then(function(r) {
            console.log(r);
            assert.equal(r.length,1);
          });
        });
      });
    });

    it("AssetsManager should be able to send 100 TIME to owner", function() {
      return Setup.assetsManager.sendAsset.call(bytes32(SYMBOL),owner,100000000).then(function(r) {
        return Setup.assetsManager.sendAsset(bytes32(SYMBOL),owner,100000000,{from: accounts[0], gas: 3000000}).then(function() {
          assert.isOk(r);
        });
      });
    });

    it("check Owner has 100 TIME", function() {
      return Setup.chronoBankAssetProxy.balanceOf.call(owner).then(function(r) {
        assert.equal(r,100000000);
      });
    });

    it("owner should be able to approve 50 TIME to Vote", function() {
      return Setup.chronoBankAssetProxy.approve.call(Setup.timeHolder.address, 50, {from: accounts[0]}).then((r) => {
        return Setup.chronoBankAssetProxy.approve(Setup.timeHolder.address, 50, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should be able to deposit 50 TIME from owner", function() {
      return Setup.timeHolder.deposit.call(50, {from: accounts[0]}).then((r) => {
        return Setup.timeHolder.deposit(50, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should show 50 TIME owner balance", function() {
      return Setup.timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {
        assert.equal(r,50);
      });
    });

    it("should be able to withdraw 25 TIME from owner", function() {
      return Setup.timeHolder.withdrawShares.call(25, {from: accounts[0]}).then((r) => {
        return Setup.timeHolder.withdrawShares(25, {from: accounts[0]}).then(() => {
          assert.isOk(r);
        });
      });
    });

    it("should show 25 TIME owner balance", function() {
      return Setup.timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {
        assert.equal(r,25);
      });
    });

  });

  context("voting", function(){

    it("should be able to create Poll 1", function() {
      return Setup.vote.manager.getVoteLimit.call().then((r) => {
        return Setup.vote.manager.NewPoll([bytes32('1'), bytes32('2')], [bytes32('1'), bytes32('2')], bytes32('New Poll1'), bytes32('New Description'), r - 1, unix + 10000, {
          from: owner,
          gas: 3000000
        }).then(() => {
          return Setup.vote.details.pollsCount.call().then((r) => {
            assert.equal(r, 1);
          });
        });
      });
    });

    it("shouldn't be able to create Poll 1 with votelimit exceeded", function() {
      return Setup.vote.manager.getVoteLimit.call().then((r) => {
        return Setup.vote.manager.NewPoll.call([bytes32('1'), bytes32('2')],[bytes32('1'), bytes32('2')], bytes32('New Poll1'), bytes32('New Description'), r + 1, unix + 10000, {
          from: owner,
          gas: 3000000
      }).then((r) => assert.equal(r, ErrorsEnum.VOTE_LIMIT_EXCEEDED))
      })
    })

    it("should be able to activate Poll 1", function() {
      return Setup.vote.manager.activatePoll(1, {from: owner}).then(() => {
        return Setup.vote.details.getActivePollsCount.call().then((r) => {
          assert.equal(r, 1)
        })
      })
    })

    it("should show owner as Poll 1 owner", function() {
      return Setup.vote.details.isPollOwner.call(1).then((r) => {
        assert.equal(r,true);
      });
    });

    it("owner1 shouldn't be able to add IPFS hash to Poll 1", function() {
      return Setup.vote.manager.addIpfsHashToPoll.call(1, bytes32('1234567890'), {from: owner1}).then((r) => {
        return Setup.vote.manager.addIpfsHashToPoll(1, bytes32('1234567890'), {from: owner1}).then(() => {
          return Setup.vote.details.getIpfsHashesFromPoll.call(1, {from: owner1}).then((r2) => {
            console.log(r, r2)
            assert.equal(r, ErrorsEnum.UNAUTHORIZED);
            assert.notEqual(r2[3], bytes32('1234567890'));
          });
        });
      });
    });

    it("owner should be able to add IPFS hash to Poll 1", function() {
      return Setup.vote.manager.addIpfsHashToPoll.call(1, bytes32('1234567890'), {from: owner}).then(function (r) {
        return Setup.vote.manager.addIpfsHashToPoll(1, bytes32('1234567890'), {from: owner}).then(function () {
          return Setup.vote.details.getIpfsHashesFromPoll.call(1, {from: owner}).then(function (r2) {
            console.log(r, r2);
            assert.equal(r2[2], bytes32('1234567890'));
          });
        });
      });
    });

    it("should provide IPFS hashes list from Poll 1 by ID", function() {
      return Setup.vote.details.getIpfsHashesFromPoll.call(1, {from: owner}).then((r) => {
        assert.equal(r.length,3);
      });
    });

    it("should be able to show Poll titles", function() {
      return Setup.vote.details.getPollTitles.call({from: owner}).then((r) => {
        assert.equal(r.length,1);
      });
    });

    it("owner should be able to vote Poll 1, Option 1", function() {
      return Setup.vote.actor.vote.call(1,1, {from: owner}).then((r) => {
        return Setup.vote.actor.vote(1,1, {from: owner}).then((r2) => {
          assert.isOk(r);
        });
      });
    });

    it("owner shouldn't be able to vote Poll 1 twice", function() {
      return Setup.vote.actor.vote.call(1,2, {from: owner}).then((r) => {
          assert.equal(r, ErrorsEnum.VOTE_POLL_ALREADY_VOTED);
      });
    });

    it("should be able to get Polls list owner took part", function() {
      return Setup.vote.details.getMemberPolls.call({from: owner}).then((r) => {
        console.log(r);
        assert.equal(r.length,1);
      });
    });

    it("should be able to get owner option for Poll 1", function() {
      return Setup.vote.details.getMemberVotesForPoll.call(1,{from: owner}).then((r) => {
        console.log(r);
        assert.equal(r,1);
      });
    });

    it("should be able to create another Poll 2", function() {
      return Setup.vote.manager.NewPoll([bytes32('Test Option 1'),bytes32('Test Option 2')],[bytes32('1'), bytes32('2')],bytes32('New Poll2'),bytes32('New Description2'),75, unix + 1000, {from: owner, gas:3000000}).then((r2) => {
        return Setup.vote.details.pollsCount.call().then((r) => {
          assert.equal(r,2);
        });
      });
    });

    it("should be able to activate Poll 2", function() {
      return Setup.vote.manager.activatePoll(2, {from: owner}).then(() => {
        return Setup.vote.details.getActivePollsCount.call().then((r) => {
          assert.equal(r,2);
        });
      });
    });

    it("should be able to show all options for Poll 1", function() {
      return Setup.vote.details.getOptionsForPoll.call(1).then((r) => {
        assert.equal(r.length,2)
      })
    })

    it("owner should be able to vote Poll 2, Option 1", function() {
      return Setup.vote.actor.vote.call(2,1, {from: owner}).then((r) => {
        return Setup.vote.actor.vote(2,1, {from: owner}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to get Polls list voter took part", function() {
      return Setup.vote.details.getMemberPolls.call({from: owner}).then((r) => {
        assert.equal(r.length,2)
      })
    })

    it("should be able to show Poll by id", function() {
      return Setup.vote.details.getPoll.call(1, {from: owner}).then((r) => {
        return Setup.vote.details.getPoll.call(2, {from: owner}).then((r2) => {
          assert.equal(r[1],bytes32('New Poll1'));
          assert.equal(r2[1],bytes32('New Poll2'));
        })
      })
    })

    it("owner1 shouldn't be able to vote Poll 1, Option 1", function() {
      return Setup.vote.actor.vote.call(1,1, {from: owner1}).then((r) => {
        assert.equal(r, ErrorsEnum.VOTE_POLL_NO_SHARES)
      })
    })

  })

  context("owner1 shares deposit and voting", function() {

    it("ChronoMint should be able to send 50 TIME to owner1", function() {
      return Setup.assetsManager.sendAsset.call(bytes32(SYMBOL),owner1,50).then(function(r) {
        return Setup.assetsManager.sendAsset(bytes32(SYMBOL),owner1,50,{from: accounts[0], gas: 3000000}).then(function() {
          assert.isOk(r)
        })
      })
    })

    it("check Owner1 has 50 TIME", function() {
      return Setup.chronoBankAssetProxy.balanceOf.call(owner1).then(function(r) {
        assert.equal(r,50)
      })
    })

    it("owner1 should be able to approve 50 TIME to TimeHolder", function() {
      return Setup.chronoBankAssetProxy.approve.call(Setup.timeHolder.address, 50, {from: owner1}).then((r) => {
        return Setup.chronoBankAssetProxy.approve(Setup.timeHolder.address, 50, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to deposit 50 TIME from owner", function() {
      return Setup.timeHolder.deposit.call(50, {from: owner1}).then((r) => {
        return Setup.timeHolder.deposit(50, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show 50 TIME owner1 balance", function() {
      return Setup.timeHolder.depositBalance.call(owner1, {from: owner1}).then((r) => {
        assert.equal(r,50)
      })
    })

    it("owner1 should be able to vote Poll 1, Option 2", function() {
      return Setup.vote.actor.vote.call(1,2, {from: owner1}).then((r) => {
        return Setup.vote.actor.vote(1,2, {from: owner1}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("Polls count should be equal to active + inactive polls", function() {
        return Setup.vote.details.getActivePollsCount.call().then((activePollsCount) => {
          return Setup.vote.details.getInactivePollsCount.call().then((inactivePollsCount) => {
            return Setup.vote.details.pollsCount.call().then((pollsCount) => {
              console.log("Active polls count:", activePollsCount);
              console.log("Inactive polls count:", inactivePollsCount);
              console.log("Polls count:", pollsCount);
              assert.isTrue(pollsCount.cmp(activePollsCount.add(inactivePollsCount)) == 0)
            })
          })
        })
    })

    it("shouldn't show Poll 2 as finished", function() {
      return Setup.vote.details.getPoll.call(2).then((r) => {
        console.log(r)
        assert.equal(r[6],true)
      });
    });

    it("owner1 should be able to vote Poll 2, Option 1", function() {
      return Setup.vote.actor.vote.call(2,1, {from: owner1}).then((r) => {
        return Setup.vote.actor.vote(2,1, {from: owner1}).then((r2) => {
          assert.isOk(r)
        })
      })
    })

    it("should show Poll 2 as finished", function() {
      return Setup.vote.details.getPoll.call(2).then((r) => {
        console.log(r)
        assert.equal(r[6],false)
      });
    });

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(1).then((r) => {
        assert.equal(r[0],25)
        assert.equal(r[1],50)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 2", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(2).then((r) => {
        assert.equal(r[0],75)
      })
    })

    it("should be able to get Polls list owner1 took part", function() {
      return Setup.vote.details.getMemberPolls.call({from: owner1}).then((r) => {
        assert.equal(r.length,2);
      })
    })

    it("shouldn't be able to create more then 20 active Polls", function() {
      this.timeout(1000000);
      return createPolls(199).then(() => {
        return Setup.vote.details.getActivePollsCount.call().then((r) => {
          return Setup.vote.details.getInactivePollsCount.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 181)
          })
        })
      })
    })

    it("should allow to delete inactive Polls for CBE admins", function() {
      return Setup.vote.manager.removePoll(100).then(() => {
        return Setup.vote.details.getActivePollsCount.call().then((r) => {
          return Setup.vote.details.getInactivePollsCount.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 180)
          })
        })
      })
    })

    it("shouldn't allow to delete inactive Polls for non CBE admins", function() {
      return Setup.vote.manager.removePoll(101,{from: owner1}).then(() => {
        return Setup.vote.details.getActivePollsCount.call().then((r) => {
          return Setup.vote.details.getInactivePollsCount.call().then((r2) => {
            assert.equal(r, 20)
            assert.equal(r2, 180)
          })
        })
      })
    })

    it("shouldn't allow to delete acvite Polls for non CBE admins", function() {
      return Setup.vote.details.checkPollIsActive.call(1).then((r) => {
        return Setup.vote.manager.removePoll(1).then(() => {
          return Setup.vote.details.getActivePollsCount.call().then((r2) => {
            return Setup.vote.details.getInactivePollsCount.call().then((r3) => {
              assert.isOk(r)
              assert.equal(r2, 20)
              assert.equal(r3, 180)
            })
          })
        })
      })
    })

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(1).then((r) => {
        console.log(r);
        assert.equal(r[0],25)
        assert.equal(r[1],50)
      })
    })

    it("should be able to withdraw 5 TIME from owner1", function() {
      return Setup.timeHolder.withdrawShares.call(5, {from: owner1}).then((r) => {
        return Setup.timeHolder.withdrawShares(5, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(1).then((r) => {
        console.log(r);
        assert.equal(r[0],25)
        assert.equal(r[1],45)
      })
    })

    it("shouldn't show Poll 1 as finished", function() {
      return Setup.vote.details.getPoll.call(1).then((r) => {
        assert.equal(r[6],true)
      })
    })

    it("should show owner1 took part in poll 0 and 1", function() {
      return Setup.vote.details.getMemberPolls.call({from: owner1}).then((r) => {
	      console.log(r)
        assert.equal(r.length,2);
      })
    })

    it("should be able to withdraw 45 TIME from owner1", function() {
      return Setup.timeHolder.withdrawShares.call(45, {from: owner1}).then((r) => {
        return Setup.timeHolder.withdrawShares(45, {from: owner1}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show owner1 took part only in finished poll 1", function() {
      return Setup.vote.details.getMemberPolls.call({from: owner1}).then((r) => {
        assert.equal(r.length,1)
      })
    })

    it("should decrese acvite Polls count", function() {
      return Setup.vote.details.getActivePollsCount.call().then((r) => {
        assert.equal(r, 20)
      })
    })

    it("owner should be able to approve 9999975 TIME to Vote", function() {
      return Setup.chronoBankAssetProxy.approve.call(Setup.timeHolder.address, 99999975, {from: accounts[0]}).then((r) => {
        return Setup.chronoBankAssetProxy.approve(Setup.timeHolder.address, 99999975, {from: accounts[0]}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should be able to deposit 9999975 TIME from owner", function() {
      return Setup.timeHolder.deposit.call(99999975, {from: accounts[0]}).then((r) => {
        return Setup.timeHolder.deposit(99999975, {from: accounts[0]}).then(() => {
          assert.isOk(r)
        })
      })
    })

    it("should show 50 TIME owner balance", function() {
      return Setup.timeHolder.depositBalance.call(owner, {from: accounts[0]}).then((r) => {
        assert.equal(r,100000000)
      })
    })

    it("should show Poll 1 as finished", function() {
      return Setup.vote.details.getPoll.call(1).then((r) => {
        console.log(r);
        assert.equal(r[6],false)
      })
    })

    it("should decrese active Polls count", function() {
      return Setup.vote.details.getActivePollsCount.call().then((r) => {
        console.log(r);
        assert.equal(r, 19)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 1", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(1).then((r) => {
        console.log(r);
        assert.equal(r[0],100000000)
        assert.equal(r[1],0)
      })
    })

    it("should be able to show number of Votes for each Option for Poll 2", function() {
      return Setup.vote.details.getOptionsVotesForPoll.call(2).then((r) => {
        assert.equal(r[0],75)
        assert.equal(r[1],0)
      })
    })

    it("should allow admin to end poll", function() {
      return Setup.vote.manager.adminEndPoll(3).then(() => {
        return Setup.vote.details.getPoll.call(3).then((r) => {
          assert.equal(r[6], false)
        })
      })
    })

    it("should decrese active Polls count", function() {
      return Setup.vote.details.getActivePollsCount.call().then((r) => {
        console.log(r);
        assert.equal(r, 18)
      })
    })

  })

})
