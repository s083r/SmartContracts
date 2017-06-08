pragma solidity ^0.4.8;

contract ContractsManagerInterface {

    enum ContractType {LOCManager, PendingManager, UserManager, ERC20Manager, ExchangeManager, TrackersManager, Voting, Rewards, AssetsManager, TimeHolder, CrowdsaleManager}
    function getContractAddressByType(ContractType _type) constant returns (address contractAddress);
    function addContract(
    address _contractAddr,
    ContractType _type)
    returns(bool);
}


