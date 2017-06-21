pragma solidity ^0.4.8;

import './Crowdsale.sol';
import './Managed.sol';
import "./AssetsManagerInterface.sol";
import "./CrowdsaleManagerEmitter.sol";
import "./Errors.sol";

/**
 * @title Crowdfunding contract
 */
contract CrowdfundingManager is Managed, CrowdfundingManagerEmitter {
    using Errors for Errors.E;

    address[] compains;

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return Errors.E.CROWDFUNDING_INVALID_INVOCATION.code();
        }

        Errors.E e = ContractsManagerInterface(_contractsManager).addContract(this, ContractsManagerInterface.ContractType.CrowdsaleManager);
        if (Errors.E.OK != e) {
            return e.code();
        }

        store.set(contractsManager, _contractsManager);

        return Errors.E.OK.code();
    }    

    function createCompain(address _creator, bytes32 _symbol) returns (uint errorCode) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager));
        if (assetsManager.isAssetOwner(_symbol, _creator)) {
            address crowdsale = new Crowdsale(store.get(contractsManager), _symbol);
            compains.push(crowdsale);
            _emitComplainCreated(_creator, _symbol, crowdsale);
            errorCode = Errors.E.OK.code();
        } else {
            errorCode = _emitError(Errors.E.CROWDFUNDING_NOT_ASSET_OWNER).code();
        }
    }

    function _emitComplainCreated(address creator, bytes32 symbol, address crowdsale) internal {
        emitComplainCreated(creator, symbol, crowdsale);
    }

    function _emitError(Errors.E error) internal returns (Errors.E) {
        emitError(error.code());
        return error;
    }
}
