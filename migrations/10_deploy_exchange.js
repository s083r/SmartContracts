var Exchange = artifacts.require("./Exchange.sol");
module.exports = function(deployer,network) {
 deployer.deploy(Exchange)
}
