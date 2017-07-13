pragma solidity ^0.4.8;

import './Crowdsale.sol';
import './Managed.sol';
import "./AssetsManagerInterface.sol";
import "./CrowdsaleManagerEmitter.sol";

/**
 * @title Crowdfunding contract
 */
contract CrowdfundingManager is Managed, CrowdfundingManagerEmitter {
    uint constant ERROR_CROWDFUNDING_INVALID_INVOCATION = 3000;
    uint constant ERROR_CROWDFUNDING_ADD_CONTRACT = 3001;
    uint constant ERROR_CROWDFUNDING_NOT_ASSET_OWNER = 3002;

    address[] compains;

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return ERROR_CROWDFUNDING_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("CrowdsaleManager"));
        if (OK != e) {
            return e;
        }

        store.set(contractsManager, _contractsManager);

        return OK;
    }

    function createCompain(address _creator, bytes32 _symbol) returns (uint errorCode) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("AssetsManager")));
        if (assetsManager.isAssetOwner(_symbol, _creator)) {
            address crowdsale = new Crowdsale(store.get(contractsManager), _symbol);
            compains.push(crowdsale);
            _emitComplainCreated(_creator, _symbol, crowdsale);
            errorCode = OK;
        } else {
            errorCode = _emitError(ERROR_CROWDFUNDING_NOT_ASSET_OWNER);
        }
    }

    function _emitComplainCreated(address creator, bytes32 symbol, address crowdsale) internal {
        emitComplainCreated(creator, symbol, crowdsale);
    }

    function _emitError(uint error) internal returns (uint) {
        emitError(error );
        return error;
    }
}
