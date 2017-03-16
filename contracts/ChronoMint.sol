pragma solidity ^0.4.8;

import "./LOC.sol";
import "./Managed.sol";

contract ChronoMint is Managed {

  uint offeringCompaniesCounter;
  mapping(uint => address) offeringCompanies;
  mapping(address => uint) offeringCompaniesIDs;
  event newLOC(address _from, address _LOC);
  event remLOC(address _from, address _LOC);
  event updLOCStatus(address _from, address _LOC);
  event updLOCValue(address _from, address _LOC);

  function init(address _userStorage, address _shareable) {
    userStorage = _userStorage;
    shareable = _shareable;
  }

  function addLOC (address _locAddr) onlyAuthorized() onlyAuthorized() execute(Shareable.Operations.editMint) {
     offeringCompanies[offeringCompaniesCounter] = _locAddr;
     offeringCompaniesIDs[_locAddr] = offeringCompaniesCounter;
     offeringCompaniesCounter++;
     newLOC(msg.sender, _locAddr);
  }

  function removeLOC(address _locAddr) onlyAuthorized() execute(Shareable.Operations.editMint) returns (bool) {
    remove(offeringCompaniesIDs[_locAddr]);
    delete offeringCompaniesIDs[_locAddr];
    remLOC(msg.sender, _locAddr);
    return true;
  }

  function remove(uint i) internal {
        if (i >= offeringCompaniesCounter) return;

        for (; i<offeringCompaniesCounter-1; i++){
            offeringCompanies[i] = offeringCompanies[i+1];
        }
        offeringCompaniesCounter--;
    }

  function proposeLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash1, bytes32 _publishedHash2, uint _expDate) onlyAuthorized() returns(address) {
    address locAddr = new LOC(_name,_website,this,_issueLimit,_publishedHash1, _publishedHash2, _expDate);
    offeringCompaniesIDs[locAddr] = offeringCompaniesCounter;
    offeringCompanies[offeringCompaniesIDs[locAddr]] = locAddr;
    offeringCompaniesCounter++;
    newLOC(msg.sender, locAddr);
    return locAddr;
  }

  function setLOCStatus(address _LOCaddr, LOC.Status status) onlyAuthorized() execute(Shareable.Operations.editLOC) {
     LOC(_LOCaddr).setStatus(status);
     updLOCStatus(msg.sender, _LOCaddr);
  }

  function setLOCValue(address _LOCaddr, LOC.Setting name, uint value) onlyAuthorized() execute(Shareable.Operations.editLOC) {
    LOC(_LOCaddr).setValue(uint(name),value);
    updLOCValue(msg.sender, _LOCaddr);  
  }

  function setLOCString(address _LOCaddr, LOC.Setting name, bytes32 value) onlyAuthorized() {
    LOC(_LOCaddr).setString(uint(name),value);
    updLOCValue(msg.sender, _LOCaddr);
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

