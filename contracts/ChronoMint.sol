pragma solidity ^0.4.8;

import "./LOC.sol";
import "./Managed.sol";

contract ChronoMint is Managed {

    uint offeringCompaniesCounter = 1;
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

    function deletedIdsLength() constant returns (uint) {
        return deletedIds.length;
    }

    function setLOCIssued(address _LOCaddr, uint _issued) isContractManager returns (bool) {
        updLOCValue(this, _LOCaddr, _issued, Configurable.Setting.issued);
        return LOC(_LOCaddr).setIssued(_issued);
    }

    function addLOC (address _locAddr) multisig returns(bool) {
        add(_locAddr);
        return true;
    }

    function add (address _locAddr) internal {
        uint id;
        if(deletedIds.length != 0) {
            id = deletedIds[deletedIds.length-1];
            deletedIds.length--;
        }
        else {
            id = offeringCompaniesCounter;
            offeringCompaniesCounter++;
        }
        offeringCompaniesIDs[_locAddr] = id;
        offeringCompanies[id] = _locAddr;
        newLOC(msg.sender, _locAddr);
    }

    function removeLOC(address _locAddr) multisig returns (bool) {
        if(offeringCompaniesIDs[_locAddr] == offeringCompaniesCounter - 1)
            offeringCompaniesCounter--;
        else
            deletedIds.push(offeringCompaniesIDs[_locAddr]);
        delete offeringCompanies[offeringCompaniesIDs[_locAddr]];
        delete offeringCompaniesIDs[_locAddr];
        remLOC(msg.sender, _locAddr);
        return true;
    }

    function proposeLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate) onlyAuthorized() returns(address) {
        address locAddr = new LOC();
        LOC(locAddr).setLOC(_name,_website,_issueLimit,_publishedHash, _expDate);
        add(locAddr);
        newLOC(msg.sender, locAddr);
        return locAddr;
    }

    function setLOCStatus(address _LOCaddr, LOC.Status status) multisig {
        LOC(_LOCaddr).setStatus(status);
        updLOCStatus(msg.sender, _LOCaddr, status);
    }

    function setLOCString(address _LOCaddr, LOC.Setting name, bytes32 value) multisig {
        LOC(_LOCaddr).setString(uint(name),value);
        updLOCString(msg.sender, _LOCaddr, value, name);
    }

    function getLOCbyID(uint _id) constant returns(address) {
        return offeringCompanies[_id];
    }

    function getLOCs() constant returns(address[] result) {
        result = new address[](offeringCompaniesCounter);
        for(uint i=1; i<offeringCompaniesCounter; i++) {
            result[i]=offeringCompanies[i];
        }
        return result;
    }

    function getLOCCount () constant returns(uint) {
        return offeringCompaniesCounter - deletedIds.length - 1;
    }

    function()
    {
        throw;
    }
}

