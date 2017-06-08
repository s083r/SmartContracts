var ProxyFactory = artifacts.require("./ProxyFactory.sol");
module.exports = function(deployer, network) {
    deployer.deploy(ProxyFactory)
}
