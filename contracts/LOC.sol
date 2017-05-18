pragma solidity ^0.4.8;

import "./Configurable.sol";
import "./ERC20Interface.sol";

contract LOC is Configurable {
    Status public status;

    function setLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate) onlyContractOwner {
        status = Status.maintenance;
        settings[uint(Setting.name)] = _name;
        settings[uint(Setting.website)] = _website;
        settings[uint(Setting.publishedHash)] = _publishedHash;
        settings[uint(Setting.issueLimit)] = bytes32(_issueLimit);
        settings[uint(Setting.expDate)] = bytes32(_expDate);
        //settings[uint(Setting.securityPercentage)] = bytes32(2);
    }

    function getContractOwner() constant returns(address) {
        return contractOwner;
    }

    function getIssueLimit() constant returns(uint) {
        return uint(settings[uint(Setting.issueLimit)]);
    }

    function getIssued() constant returns(uint) {
        return uint(settings[uint(Setting.issued)]);
    }

    function setIssued(uint _issued) onlyContractOwner returns(bool) {
        settings[uint(Setting.issued)] = bytes32(_issued);
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

    function()
    {
        throw;
    }
}
