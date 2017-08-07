var FakeCoin = artifacts.require("./FakeCoin.sol");

module.exports = function(deployer,network) {
  // deploy FakeCoin only in non-main networks
  if(network !== 'main') {
      // check whether FakeCoin has been already deployed or not
      if (!FakeCoin.isDeployed()) {
          return deployer.deploy(FakeCoin)
            .then(() => console.log("[MIGRATION] [36] Deploy FakeCoin: #done"));
      } else {
          console.log("[MIGRATION] [36] Deploy FakeCoin: #skiped, already deployed");
      }
  } else {
      console.log("[MIGRATION] [36] Deploy FakeCoin: #skiped, main network");
  }
}
