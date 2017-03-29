pragma solidity ^0.4.8;

import "./Configurable.sol";
import "./ERC20Interface.sol";

contract LOC is Configurable {
    Status public status;

    function LOC(bytes32 _name, bytes32 _website, address _controller, uint _issueLimit, bytes32 _publishedHash1, bytes32 _publishedHash2, uint _expDate){
        status = Status.maintenance;
        contractOwner = _controller;
        settings[uint(Setting.name)] = _name;
        settings[uint(Setting.website)] = _website;
        settings[uint(Setting.publishedHash1)] = _publishedHash1;
        settings[uint(Setting.publishedHash2)] = _publishedHash2;
        values[uint(Setting.issueLimit)] = _issueLimit;
        values[uint(Setting.expDate)] = _expDate;
    }

    function getContractOwner() constant returns(address) {
        return contractOwner;
    }

    function getIssueLimit() constant returns(uint) {
        return values[uint(Setting.issueLimit)];
    }

    function getIssued() constant returns(uint) {
        return values[uint(Setting.issued)];
    }

    function setIssued(uint _issued) onlyContractOwner returns(bool) {
        values[uint(Setting.issued)] = _issued;
        return true;
    }

    function getName() constant returns(bytes32) {
        return settings[uint(Setting.name)];
    }

    function setStatus(Status _status) onlyContractOwner {
        status = _status;
    }

    function setName(bytes32 _name) onlyContractOwner {
        settings[uint(Setting.name)] = _name;
    }

    function setWebsite(bytes32 _website) onlyContractOwner {
        settings[uint(Setting.website)] = _website;
    }

    function sendAsset(address _lhAddr, address _to, uint _value) onlyContractOwner returns (bool) {
        return ERC20Interface(_lhAddr).transfer(_to, _value);
    }

    function()
    {
        throw;
    }
}
