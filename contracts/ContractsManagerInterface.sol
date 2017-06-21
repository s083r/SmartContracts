pragma solidity ^0.4.11;

import "./Errors.sol";

contract ContractsManagerInterface {
    enum ContractType {
      LOCManager,
      PendingManager,
      UserManager,
      ERC20Manager,
      ExchangeManager,
      TrackersManager,
      Voting,
      Rewards,
      AssetsManager,
      TimeHolder,
      CrowdsaleManager
    }

    function getContractAddressByType(ContractType _type) constant returns (address contractAddress);
    function addContract(address _contractAddr, ContractType _type) returns (Errors.E);
}
