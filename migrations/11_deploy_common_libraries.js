const ErrorLibrary = artifacts.require("./Errors.sol");

module.exports = function(deployer, network) {
    deployer.deploy(ErrorLibrary)
        .then(() => console.log("[MIGRATION] [11] ErrorLibrary: #done"))
}
