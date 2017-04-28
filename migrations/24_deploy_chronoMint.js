var ChronoMint = artifacts.require("./ChronoMint.sol");
module.exports = function(deployer, network) {
    deployer.deploy(ChronoMint)
}
