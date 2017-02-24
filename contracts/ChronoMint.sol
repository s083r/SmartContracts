pragma solidity ^0.4.8;

import "./ContractsManager.sol";
import "./LOC.sol";

contract ChronoMint is ContractsManager {
  uint offeringCompaniesCounter;
  mapping(uint => address) offeringCompanies;
  mapping(address => uint) offeringCompaniesIDs;
  event newLOC(address _from, address _LOC);

  function isCBE(address key) constant returns(bool) {
      if (isAuthorized(msg.sender)) {
         return true;
      }
      return false;
  }

  function pendingsCount() constant returns(uint) {
    return pendingsIndex.length;
  }
  
  function pendingById(uint _id) constant returns(bytes32) {
    return pendingsIndex[_id];
  }
  
  function pendingYetNeeded(bytes32 _hash) constant returns(uint) {
    return pendings[_hash].yetNeeded;
  }
 
  function addLOC (address _locAddr) onlyAuthorized() onlyAuthorized() execute(Operations.editMint) {
     offeringCompanies[offeringCompaniesCounter] = _locAddr;
     offeringCompaniesIDs[_locAddr] = offeringCompaniesCounter;
     offeringCompaniesCounter++;
  }

  function removeLOC(address _locAddr) onlyAuthorized() execute(Operations.editMint) returns (bool) {
    remove(offeringCompaniesIDs[_locAddr]);
    delete offeringCompaniesIDs[_locAddr];
    return true;
  }

  function remove(uint i) {
        if (i >= offeringCompaniesCounter) return;

        for (; i<offeringCompaniesCounter-1; i++){
            offeringCompanies[i] = offeringCompanies[i+1];
        }
        offeringCompaniesCounter--;
    }

  function proposeLOC(string _name, string _website, uint _issueLimit, string _publishedHash, uint _expDate) onlyAuthorized() returns(address) {
    address locAddr = new LOC(_name,_website,this,_issueLimit,_publishedHash,_expDate);
    offeringCompaniesIDs[locAddr] = offeringCompaniesCounter;
    offeringCompanies[offeringCompaniesIDs[locAddr]] = locAddr;
    offeringCompaniesCounter++;
    newLOC(msg.sender, locAddr);
    return locAddr;
  }

  function setLOCStatus(address _LOCaddr, Status status) onlyAuthorized() execute(Operations.editLOC) {
     LOC(_LOCaddr).setStatus(status);
  }

  function setLOCValue(address _LOCaddr, Setting name, uint value) onlyAuthorized() execute(Operations.editLOC) {
    LOC(_LOCaddr).setValue(uint(name),value);
  }

  function setLOCString(address _LOCaddr, Setting name, string value) onlyAuthorized() {
    LOC(_LOCaddr).setString(uint(name),value);
  }

  function getLOCbyID(uint _id) onlyAuthorized() returns(address) {
    return offeringCompanies[_id];
  }

  function getLOCs() onlyAuthorized() returns(address[] result) {
    result = new address[](offeringCompaniesCounter);
    for(uint i=0; i<offeringCompaniesCounter; i++) {
       result[i]=offeringCompanies[i];
    }
    return result;
  }

  function getLOCCount () onlyAuthorized() returns(uint) {
      return offeringCompaniesCounter;
  }

  function ChronoMint(address _eS, address _tpc) {
    eternalStorage = _eS;
    values[uint(Setting.securityPercentage)] = 1;
    values[uint(Setting.liquidityPercentage)] = 1;
    values[uint(Setting.insurancePercentage)] = 1;
    values[uint(Setting.insuranceDuration)] = 1;
  }

  function()
  {
    throw;
  }
}

