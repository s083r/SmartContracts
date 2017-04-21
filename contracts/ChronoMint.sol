pragma solidity ^0.4.8;

import "./LOC.sol";
import "./Managed.sol";

contract ChronoMint is Managed {

    uint offeringCompaniesCounter;
    uint[] deletedIds;
    address contractManager;
    mapping(uint => address) offeringCompanies;
    mapping(address => uint) offeringCompaniesIDs;
    event newLOC(address _from, address _LOC);
    event remLOC(address _from, address _LOC);
    event updLOCStatus(address _from, address _LOC, LOC.Status _status);
    event updLOCValue(address _from, address _LOC, uint _value, Configurable.Setting _name);
    event updLOCString(address _from, address _LOC, bytes32 _value, Configurable.Setting _name);

    function init(address _userStorage, address _shareable, address _contractManager) returns(bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        contractManager = _contractManager;
        return true;
    }

    modifier isContractManager() {
        if (msg.sender == contractManager) {
            _;
        }
    }

    function deletedIdsLength() returns (uint) {
        return deletedIds.length;
    }

    function setLOCIssued(address _LOCaddr, uint _issued) isContractManager returns (bool) {
        updLOCValue(this, _LOCaddr, _issued, Configurable.Setting.issued);
        return LOC(_LOCaddr).setIssued(_issued);
    }

    function addLOC (address _locAddr) execute(Shareable.Operations.editMint) {
        if(deletedIds.length != 0) {
            offeringCompaniesIDs[_locAddr] = deletedIds[deletedIds.length-1];
            offeringCompanies[deletedIds[deletedIds.length-1]] = _locAddr;
            deletedIds.length--;
        }
        else {
            offeringCompaniesIDs[_locAddr] = offeringCompaniesCounter;
            offeringCompanies[offeringCompaniesIDs[_locAddr]] = _locAddr;
            offeringCompaniesCounter++;

        }
        newLOC(msg.sender, _locAddr);
    }

    function removeLOC(address _locAddr) execute(Shareable.Operations.editMint) returns (bool) {
        delete offeringCompanies[offeringCompaniesIDs[_locAddr]];
        deletedIds.push(offeringCompaniesIDs[_locAddr]);
        delete offeringCompaniesIDs[_locAddr];
        remLOC(msg.sender, _locAddr);
        return true;
    }

    function proposeLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate) onlyAuthorized() returns(address) {
        address locAddr = new LOC(_name,_website,this,_issueLimit,_publishedHash, _expDate);
        if(deletedIds.length != 0) {
            offeringCompaniesIDs[locAddr] = deletedIds[deletedIds.length-1];
            offeringCompanies[deletedIds[deletedIds.length-1]] = locAddr;
            deletedIds.length--;
        }
        else {
            offeringCompaniesIDs[locAddr] = offeringCompaniesCounter;
            offeringCompanies[offeringCompaniesIDs[locAddr]] = locAddr;
            offeringCompaniesCounter++;

        }
        newLOC(msg.sender, locAddr);
        return locAddr;
    }

    function setLOCStatus(address _LOCaddr, LOC.Status status) execute(Shareable.Operations.editLOC) {
        LOC(_LOCaddr).setStatus(status);
        updLOCStatus(msg.sender, _LOCaddr, status);
    }

    function setLOCValue(address _LOCaddr, LOC.Setting name, uint value) execute(Shareable.Operations.editLOC) {
        LOC(_LOCaddr).setValue(uint(name),value);
        updLOCValue(msg.sender, _LOCaddr, value, name);
    }

    function setLOCString(address _LOCaddr, LOC.Setting name, bytes32 value) onlyAuthorized() {
        LOC(_LOCaddr).setString(uint(name),value);
        updLOCString(msg.sender, _LOCaddr, value, name);
    }

    function getLOCbyID(uint _id) constant returns(address) {
        return offeringCompanies[_id];
    }

    function getLOCs() constant returns(address[] result) {
        result = new address[](offeringCompaniesCounter);
        for(uint i=0; i<offeringCompaniesCounter; i++) {
            result[i]=offeringCompanies[i];
        }
        return result;
    }

    function getLOCCount () constant returns(uint) {
        return offeringCompaniesCounter;
    }

    function()
    {
        throw;
    }
}

