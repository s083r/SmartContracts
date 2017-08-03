pragma solidity ^0.4.11;

import '../core/common/BaseManager.sol';
import "../assets/AssetsManagerInterface.sol";
import './Crowdsale.sol';
import "./CrowdsaleManagerEmitter.sol";

/**
 * @title Crowdfunding contract
 */
contract CrowdfundingManager is CrowdfundingManagerEmitter, BaseManager {
    uint constant ERROR_CROWDFUNDING_INVALID_INVOCATION = 3000;
    uint constant ERROR_CROWDFUNDING_ADD_CONTRACT = 3001;
    uint constant ERROR_CROWDFUNDING_NOT_ASSET_OWNER = 3002;

    address[] compains;

    function init(address _contractsManager) onlyContractOwner returns (uint) {
        BaseManager.init(_contractsManager, "CrowdsaleManager");

        return OK;
    }

    function createCompain(bytes32 _symbol) returns (uint errorCode) {
        return createCompain(msg.sender, _symbol);
    }

    function createCompain(address _creator, bytes32 _symbol) internal returns (uint errorCode) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(lookupManager("AssetsManager"));
        if (assetsManager.isAssetOwner(_symbol, _creator)) {
            address crowdsale = new Crowdsale(contractsManager, _symbol);
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
