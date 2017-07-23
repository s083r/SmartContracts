const UserManager = artifacts.require("./UserManager.sol");
const Q = require("q");

var exit = function () {
  process.exit()
}

var setupCBE = function (callback) {
  if (this.artifacts.options.network === "main") {
      throw new Error('Is not alloved for main network!');
  }

  const addresses = [
    "0xc38f003c0a14a05f11421d793edc9696a25cb2b3",
    "0x64a5d8B41BA9D01D64016164BF5B51B48440D46d",
    "0x281bda743d5abcc94d54b604ab1462f4c6c6d6c2",
    "0x00d451bedd4f8567631b5811c1d3d57cfd410ddd"
  ]

  let _setupCBE = (userManager, addresses) => {
    var chain = Q.when();

    for(let address of addresses) {
         chain = chain.then(function() {
            return userManager.addCBE(address, 0x1)
                      .then(() => userManager.isAuthorized.call(address))
                      .then((r) => {if (r) {console.log(address + " is CBE");} return r;});
         });
    }

    return Q.all(chain);
  }

  return UserManager.deployed()
    .then(_userManager => _setupCBE(_userManager, addresses))
    .then(() => callback())
    .catch(function (e) {
        console.log(e)
        callback(e);
      })
}

module.exports.setupCBE = setupCBE

module.exports = (callback) => {
  return setupCBE(callback)
}
