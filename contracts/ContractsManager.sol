pragma solidity ^0.4.8;

import "./Managed.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ERC20Interface.sol";
import "./ExchangeInterface.sol";
import "./OwnedInterface.sol";
import "./LOCInterface.sol";
import "./ChronoMintInterface.sol";
import "./FeeInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";

contract ContractsManager is Managed {
    address internal platform;
    uint public contractsCounter = 1;
    uint public otherContractsCounter = 1;
    mapping (address => bool) public timeHolder;
    mapping (uint => address) internal contracts;
    mapping (uint => address) internal otherContracts;
    mapping (address => uint) internal contractsId;
    mapping (address => uint) internal otherContractsId;
    mapping (uint => bytes32) internal contractsHash1;
    mapping (uint => bytes32) internal otherContractsHash1;

    event updateContract(address contractAddress);
    event updateOtherContract(address contractAddress);
    event reissue(uint value, address locAddr);

    function init(address _userStorage, address _shareable) returns (bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        return true;
    }
//this method is implemented only for test purporses
    function sendTime() returns (bool) {
        if(!timeHolder[msg.sender]) {
            timeHolder[msg.sender] = true;
            return ERC20Interface(contracts[1]).transfer(msg.sender, 1000);
        }
        else {
            return false;
        }
    }

    function setContractHash(uint _id, bytes32 _hash1) onlyAuthorized() returns (bool) {
        contractsHash1[_id] = _hash1;
        return true;
    }

    function setOtherContractHash(uint _id, bytes32 _hash1) onlyAuthorized() returns (bool) {
        otherContractsHash1[_id] = _hash1;
        return true;
    }

    function getContractHash(uint _id) constant returns (bytes32) {
        return (contractsHash1[_id]);
    }

    function getOtherContractHash(uint _id) constant returns (bytes32) {
        return (otherContractsHash1[_id]);
    }

    function getAssetBalances(bytes32 _symbol, uint _startId, uint _num) constant
    returns (address[] result, uint[] result2) {
        if (_num <= 100) {
            result = new address[](_num);
            result2 = new uint[](_num);
            for (uint i = 0; i < _num; i++)
            {
                address owner = ChronoBankPlatformInterface(platform)._address(_startId);
                uint balance = ChronoBankPlatformInterface(platform)._balanceOf(_startId, _symbol);
                result[i] = owner;
                result2[i] = balance;
                _startId++;
            }
            return (result, result2);
        }
        throw;
    }

    function getContracts() constant returns (address[] result) {
        result = new address[](contractsCounter - 1);
        for (uint i = 0; i < contractsCounter - 1; i++) {
            result[i] = contracts[i + 1];
        }
        return result;
    }

    function getOtherContracts() constant returns (address[] result) {
        result = new address[](otherContractsCounter - 1);
        for (uint i = 0; i < otherContractsCounter - 1; i++) {
            result[i] = otherContracts[i + 1];
        }
        return result;
    }

    function claimPlatformOwnership(address _addr) onlyAuthorized() returns (bool) {
        if (OwnedInterface(_addr).claimContractOwnership()) {
            platform = _addr;
            return true;
        }
        return false;
    }

    function claimExchangeOwnership(address _addr) onlyAuthorized() returns (bool) {
        if (OwnedInterface(_addr).claimContractOwnership()) {
            return true;
        }
        return false;
    }

    function setExchangePrices(address _ec, uint _buyPrice, uint _sellPrice) onlyAuthorized() returns (bool) {
        return ExchangeInterface(_ec).setPrices(_buyPrice, _sellPrice);
    }

    function reissueAsset(bytes32 _symbol, uint _value, address _locAddr) execute(Shareable.Operations.editMint) returns (bool) {
        if (platform != 0x0) {
            uint issued = LOCInterface(_locAddr).getIssued();
            if(_value <= LOCInterface(_locAddr).getIssueLimit() - issued) {
                if(ChronoBankPlatformInterface(platform).reissueAsset(_symbol, _value)) {
                    address Mint = LOCInterface(_locAddr).getContractOwner();
                    reissue(_value, _locAddr);
                    return ChronoMintInterface(Mint).call(bytes4(sha3("setLOCIssued(address,uint256)")), _locAddr, issued + _value);
                }
            }
        }
        return false;
    }

    function revokeAsset(bytes32 _symbol, uint _value, address _locAddr) execute(Shareable.Operations.editMint) returns (bool) {
        if (platform != 0x0) {
            uint issued = LOCInterface(_locAddr).getIssued();
            if(_value <= issued) {
                if(ChronoBankPlatformInterface(platform).revokeAsset(_symbol, _value)) {
                    address Mint = LOCInterface(_locAddr).getContractOwner();
                    reissue(_value, _locAddr);
                    return ChronoMintInterface(Mint).call(bytes4(sha3("setLOCIssued(address,uint256)")), _locAddr, issued - _value);
                }
            }
        }
        return false;
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) onlyAuthorized() returns (bool) {
        if(_symbol == bytes32('LHT')) {
            address assetProxy = ChronoBankPlatformInterface(platform).proxies(_symbol);
            uint feePercent = FeeInterface(ChronoBankAssetProxyInterface(assetProxy).getLatestVersion()).feePercent();
            uint amount = (_value * 10000)/(10000 + feePercent);
            return ERC20Interface(ChronoBankPlatformInterface(platform).proxies(_symbol)).transfer(_to, amount);
        }
        return ERC20Interface(ChronoBankPlatformInterface(platform).proxies(_symbol)).transfer(_to, _value);
    }

    function getBalance(uint _id) constant returns (uint) {
        return ERC20Interface(contracts[_id]).balanceOf(this);
    }

    function getAddress(uint _id) constant returns (address) {
        return contracts[_id];
    }

    function setAddress(address value) execute(Shareable.Operations.editMint) returns (uint) {
        if (contractsId[value] == uint(0x0)) {
            contracts[contractsCounter] = value;
            contractsId[value] = contractsCounter;
            updateContract(value);
            return contractsCounter++;
        }
        return contractsId[value];
    }

    function changeAddress(address _from, address _to) execute(Shareable.Operations.editMint) returns (bool) {
        if (contractsId[_from] != 0) {
            contracts[contractsId[_from]] = _to;
            contractsId[_to] = contractsId[_from];
            delete contractsId[_from];
            updateContract(_to);
            return true;
        }
        return false;
    }

    function removeAddress(address value) execute(Shareable.Operations.editMint) {
        removeAddr(contractsId[value]);
        delete contractsId[value];
        updateContract(value);
    }

    function removeAddr(uint i) internal {
        if (i >= contractsCounter) return;
        for (; i < contractsCounter; i++) {
            contracts[i] = contracts[i + 1];
        }
        delete contracts[i + 1];
        contractsCounter--;
    }

    function getOtherAddress(uint _id) constant returns (address) {
        return otherContracts[_id];
    }

    function setOtherAddress(address value) execute(Shareable.Operations.editMint) returns (uint) {
        if (otherContractsId[value] == uint(0x0)) {
            otherContracts[otherContractsCounter] = value;
            otherContractsId[value] = otherContractsCounter;
            updateOtherContract(value);
            otherContractsCounter++;
            return otherContractsCounter;
        }
        return otherContractsId[value];
    }

    function changeOtherAddress(address _from, address _to) execute(Shareable.Operations.editMint) returns (bool) {
        if (otherContractsId[_from] != 0) {
            otherContracts[otherContractsId[_from]] = _to;
            otherContractsId[_to] = otherContractsId[_from];
            delete otherContractsId[_from];
            updateOtherContract(_to);
            return true;
        }
        return false;
    }

    function removeOtherAddress(address value) execute(Shareable.Operations.editMint) {
        removeOtherAddr(otherContractsId[value]);
        delete otherContractsId[value];
        updateOtherContract(value);
    }

    function removeOtherAddr(uint i) internal {
        if (i >= otherContractsCounter) return;
        for (; i < otherContractsCounter; i++) {
            otherContracts[i] = otherContracts[i + 1];
        }
        otherContractsCounter--;
    }

    function()
    {
        throw;
    }
}
