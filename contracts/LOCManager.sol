pragma solidity ^0.4.8;

import "./Managed.sol";
import "./AssetsManagerInterface.sol";
import "./ERC20Interface.sol";
import "./ERC20ManagerInterface.sol";
import "./FeeInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";
import "./LOCManagerEmitter.sol";

contract LOCManager is Managed, LOCManagerEmitter {

    uint constant ERROR_LOC_NOT_FOUND = 1000;
    uint constant ERROR_LOC_EXISTS = 1001;
    uint constant ERROR_LOC_INACTIVE = 1002;
    uint constant ERROR_LOC_SHOULD_NO_BE_ACTIVE = 1003;
    uint constant ERROR_LOC_INVALID_PARAMETER = 1004;
    uint constant ERROR_LOC_INVALID_INVOCATION = 1005;
    uint constant ERROR_LOC_ADD_CONTRACT = 1006;
    uint constant ERROR_LOC_SEND_ASSET = 1007;
    uint constant ERROR_LOC_REQUESTED_ISSUE_VALUE_EXCEEDED = 1008;
    uint constant ERROR_LOC_REISSUING_ASSET_FAILED = 1009;
    uint constant ERROR_LOC_REQUESTED_REVOKE_VALUE_EXCEEDED = 1010;
    uint constant ERROR_LOC_REVOKING_ASSET_FAILED = 1011;

    StorageInterface.Set offeringCompaniesNames;
    StorageInterface.Bytes32Bytes32Mapping website;
    StorageInterface.Bytes32Bytes32Mapping publishedHash;
    StorageInterface.Bytes32Bytes32Mapping currency;
    StorageInterface.Bytes32UIntMapping issued;
    StorageInterface.Bytes32UIntMapping issueLimit;
    StorageInterface.Bytes32UIntMapping expDate;
    StorageInterface.Bytes32UIntMapping status;
    StorageInterface.Bytes32UIntMapping createDate;

    enum Status {maintenance, active, suspended, bankrupt}

    function LOCManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        offeringCompaniesNames.init('offeringCompaniesNames');
        website.init('website');
        publishedHash.init('publishedHash');
        currency.init('currency');
        issued.init('issued');
        issueLimit.init('issueLimit');
        expDate.init('expDate');
        status.init('status');
        createDate.init('createDate');
    }

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return ERROR_LOC_INVALID_INVOCATION;
        }

        uint errorCode =  ContractsManagerInterface(_contractsManager).addContract(this, bytes32("LOCManager"));
        if (OK != errorCode) {
            return errorCode;
        }

        store.set(contractsManager, _contractsManager);
        return OK;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_LOC_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function isLOCExist(bytes32 _locName) private constant returns (bool) {
        return store.includes(offeringCompaniesNames, _locName);
    }

    function isLOCActive(bytes32 _locName) private constant returns (bool) {
        return store.get(status, _locName) == uint(Status.active);
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("AssetsManager"))).sendAsset(_symbol, _to, _value)) {
            return _emitError(ERROR_LOC_SEND_ASSET);
        }

        _emitAssetSent(_symbol, _to, _value);
        return OK;
    }

    function reissueAsset(uint _value, bytes32 _locName) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!isLOCActive(_locName)) {
            return _emitError(ERROR_LOC_INACTIVE);
        }

        uint _issued = store.get(issued, _locName);
        if (_value <= store.get(issueLimit, _locName) - _issued) {
            if (AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("AssetsManager"))).reissueAsset(store.get(currency, _locName), _value)) {
                store.set(issued, _locName, _issued + _value);
                _emitReissue(_locName, _value);
                errorCode = OK;
            } else {
                errorCode = _emitError(ERROR_LOC_REISSUING_ASSET_FAILED);
            }
        } else {
            errorCode = _emitError(ERROR_LOC_REQUESTED_ISSUE_VALUE_EXCEEDED);
        }
    }

    function revokeAsset(uint _value, bytes32 _locName) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!isLOCActive(_locName)) {
            return _emitError(ERROR_LOC_INACTIVE);
        }

        uint _issued = store.get(issued, _locName);
        if (_value <= _issued) {
            if (AssetsManagerInterface(ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("AssetsManager"))).revokeAsset(store.get(currency, _locName), _value)) {
                store.set(issued, _locName, _issued - _value);
                _emitRevoke(_locName, _value);
                errorCode = OK;
            }
            else {
                errorCode = _emitError(ERROR_LOC_REVOKING_ASSET_FAILED);
            }
        }
        else {
            errorCode = _emitError(ERROR_LOC_REQUESTED_REVOKE_VALUE_EXCEEDED);
        }
    }

    function removeLOC(bytes32 _name) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!isLOCExist(_name)) {
            return _emitError(ERROR_LOC_NOT_FOUND);
        }

        if (isLOCActive(_name)) {
            return _emitError(ERROR_LOC_SHOULD_NO_BE_ACTIVE);
        }

        store.remove(offeringCompaniesNames, _name);
        store.set(website, _name, 0);
        store.set(issueLimit, _name, 0);
        store.set(issued, _name, 0);
        store.set(createDate, _name, 0);
        store.set(publishedHash, _name, 0);
        store.set(expDate, _name, 0);
        store.set(currency, _name, 0);
        store.set(createDate, _name, 0);
        _emitRemLOC(_name);

        return OK;
    }

    function addLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate, bytes32 _currency) onlyAuthorized returns (uint) {
        if (isLOCExist(_name)) {
            return _emitError(ERROR_LOC_EXISTS);
        }

        store.add(offeringCompaniesNames, _name);
        store.set(website, _name, _website);
        store.set(issueLimit, _name, _issueLimit);
        store.set(publishedHash, _name, _publishedHash);
        store.set(expDate, _name, _expDate);
        store.set(currency, _name, _currency);
        store.set(createDate, _name, now);
        _emitNewLOC(_name, store.count(offeringCompaniesNames));

        return OK;
    }

    function setLOC(bytes32 _name, bytes32 _newname, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate) onlyAuthorized returns (uint) {
        if (!isLOCExist(_name)) {
            return _emitError(ERROR_LOC_NOT_FOUND);
        }

        if (isLOCActive(_name)) {
            return _emitError(ERROR_LOC_SHOULD_NO_BE_ACTIVE);
        }

        if (_newname == bytes32(0)) {
            return _emitError(ERROR_LOC_INVALID_PARAMETER);
        }

        if (!(_newname == _name)) {
            store.set(offeringCompaniesNames, _name, _newname);
            store.set(website, _newname, store.get(website, _name));
            store.set(issueLimit, _newname, store.get(issueLimit, _name));
            store.set(publishedHash, _newname, store.get(publishedHash, _name));
            store.set(expDate, _newname, store.get(expDate, _name));
            store.set(currency, _newname, store.get(currency, _name));
            store.set(createDate, _newname, store.get(createDate, _name));
            _emitUpdLOCName(_name, _newname);
            _name = _newname;
        }
        if (!(_website == store.get(website, _name))) {
            store.set(website, _name, _website);
        }
        if (!(_issueLimit == store.get(issueLimit, _name))) {
            store.set(issueLimit, _name, _issueLimit);
        }
        if (!(_publishedHash == store.get(publishedHash, _name))) {
            _emitHashUpdate(_name, store.get(publishedHash, _name), _publishedHash);
            store.set(publishedHash, _name, _publishedHash);
        }
        if (!(_expDate == store.get(expDate, _name))) {
            store.set(expDate, _name, _expDate);
        }

        return OK;
    }

    function setStatus(bytes32 _name, Status _status) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!isLOCExist(_name)) {
            return _emitError(ERROR_LOC_NOT_FOUND);
        }

        if (store.get(status, _name) == uint(_status)) {
            return _emitError(ERROR_LOC_INVALID_PARAMETER);
        }

        store.set(status, _name, uint(_status));
        _emitUpdLOCStatus(_name, store.get(status, _name), uint(_status));

        return OK;
    }

    function getLOCByName(bytes32 _name) constant returns (bytes32 _locName, bytes32 _website,
    uint _issued,
    uint _issueLimit,
    bytes32 _publishedHash,
    uint _expDate,
    uint _status,
    uint _securityPercentage,
    bytes32 _currency,
    uint _createDate) {
        _website = store.get(website, _name);
        _issued = store.get(issued, _name);
        _issueLimit = store.get(issueLimit, _name);
        _publishedHash = store.get(publishedHash, _name);
        _expDate = store.get(expDate, _name);
        _status = store.get(status, _name);
        _currency = store.get(currency, _name);
        _createDate = store.get(createDate, _name);
        return (_name, _website, _issued, _issueLimit, _publishedHash, _expDate, _status, 10, _currency, _createDate);
    }

    function getLOCById(uint _id) constant returns (bytes32 locName, bytes32 website,
    uint issued,
    uint issueLimit,
    bytes32 publishedHash,
    uint expDate,
    uint status,
    uint securityPercentage,
    bytes32 currency,
    uint creatrDate) {
        bytes32 _name = store.get(offeringCompaniesNames, _id);
        return getLOCByName(_name);
    }

    function getLOCNames() constant returns (bytes32[]) {
        return store.get(offeringCompaniesNames);
    }

    function getLOCCount() constant returns (uint) {
        return store.count(offeringCompaniesNames);
    }

    function _emitNewLOC(bytes32 _locName, uint count) internal {
        LOCManager(getEventsHistory()).emitNewLOC(_locName, count);
    }

    function _emitRemLOC(bytes32 _locName) internal {
        LOCManager(getEventsHistory()).emitRemLOC(_locName);
    }

    function _emitUpdLOCName(bytes32 _locName, bytes32 _newName) internal {
        LOCManager(getEventsHistory()).emitUpdLOCName(_locName, _newName);
    }

    function _emitUpdLOCStatus(bytes32 _locName, uint _oldStatus, uint _newStatus) internal {
        LOCManager(getEventsHistory()).emitUpdLOCStatus(_locName, _oldStatus, _newStatus);
    }

    function _emitHashUpdate(bytes32 _locName, bytes32 _oldHash, bytes32 _newHash) internal {
        LOCManager(getEventsHistory()).emitHashUpdate(_locName, _oldHash, _newHash);
    }

    function _emitReissue(bytes32 _locName, uint _value) internal {
        LOCManager(getEventsHistory()).emitReissue(_locName, _value);
    }

    function _emitRevoke(bytes32 _locName, uint _value) internal {
        LOCManager(getEventsHistory()).emitRevoke(_locName, _value);
    }

    function _handleResult(uint error) internal returns (uint) {
        if (error != OK && error != MULTISIG_ADDED) {
            return _emitError(error);
        }
        return error;
    }

    function _emitError(uint error) internal returns (uint) {
        LOCManager(getEventsHistory()).emitError(error);
        return error;
    }

    function _emitAssetSent(bytes32 symbol, address to, uint value) internal  {
        LOCManager(getEventsHistory()).emitAssetSent(symbol, to, value);
    }

    function() {
        throw;
    }
}
