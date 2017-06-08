pragma solidity ^0.4.8;
import './Crowdsale.sol';
import './Managed.sol';
import "./AssetsManagerInterface.sol";

/**
 * @title Crowdfunding contract
 */
contract CrowdfundingManager is Managed {

    address[] compains;

    function init(address _contractsManager) returns(bool) {
        if(store.get(contractsManager) != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.CrowdsaleManager))
        return false;
        store.set(contractsManager,_contractsManager);
        return true;
    }

    function createCompain(address _creator, bytes32 _symbol) returns(address) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager));
        if(assetsManager.isAssetOwner(_symbol,_creator))
        {
            address crowdsale = new Crowdsale(store.get(contractsManager),_symbol);
            compains.push(crowdsale);
            return crowdsale;
        }
    }

}