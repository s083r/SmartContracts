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
    uint public contractsCounter = 1;
    uint public otherContractsCounter = 1;
    mapping (address => bool) public timeHolder;
    mapping (uint => address) internal contracts;
    mapping (uint => address) internal otherContracts;
    mapping (address => uint) internal contractsId;
    mapping (address => uint) internal otherContractsId;
    mapping (uint => bytes32) internal contractsHash;
    mapping (uint => bytes32) internal otherContractsHash;

    event UpdateContract(address contractAddress, uint id);
    event UpdateOtherContract(address contractAddress, uint id);
    event Reissue(uint value, address locAddr);

    function init(address _userStorage, address _shareable) returns (bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        return true;
    }

    // this method is implemented only for test purposes
    function sendTime() returns (bool) {
        if(!timeHolder[msg.sender]) {
            timeHolder[msg.sender] = true;
            return ERC20Interface(contracts[1]).transfer(msg.sender, 1000000000);
        }
        else {
            return false;
        }
    }

    function setContractHash(uint _id, bytes32 _hash) onlyAuthorized() returns (bool) {
        contractsHash[_id] = _hash;
        return true;
    }

    function setOtherContractHash(uint _id, bytes32 _hash) onlyAuthorized() returns (bool) {
        otherContractsHash[_id] = _hash;
        return true;
    }

    function getContractHash(uint _id) constant returns (bytes32) {
        return (contractsHash[_id]);
    }

    function getOtherContractHash(uint _id) constant returns (bytes32) {
        return (otherContractsHash[_id]);
    }

    function getAssetBalances(uint _id, uint _startId, uint _num) constant returns (address[] result, uint[] result2) {
        if(contracts[_id] != 0x0) {
            address platform = ChronoBankAssetProxyInterface(contracts[_id]).chronoBankPlatform();
            if (platform != 0x0) {
                bytes32 symbol = ChronoBankAssetProxyInterface(contracts[_id]).smbl();
                if (_num <= 100) {
                    result = new address[](_num);
                    result2 = new uint[](_num);
                    for (uint i = 0; i < _num; i++)
                    {
                        address owner = ChronoBankPlatformInterface(platform)._address(_startId);
                        uint balance = ChronoBankPlatformInterface(platform)._balanceOf(_startId, bytes32(symbol));
                        result[i] = owner;
                        result2[i] = balance;
                        _startId++;
                    }
                    return (result, result2);
                }
            }
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

    function claimContractOwnership(address _addr, bool _erc20) onlyAuthorized() returns (bool) {
        if (OwnedInterface(_addr).claimContractOwnership()) {
            if(_erc20) {
                setAddressInt(_addr);
            }
            else {
                setOtherAddressInt(_addr);
            }
            return true;
        }
        return false;
    }

//    function claimExchangeOwnership(address _addr) onlyAuthorized() returns (bool) {
//        if (OwnedInterface(_addr).claimContractOwnership()) {
//            return true;
//        }
//        return false;
//    }

//    function setExchangePrices(address _ec, uint _buyPrice, uint _sellPrice) onlyAuthorized() returns (bool) {
//        return ExchangeInterface(_ec).setPrices(_buyPrice, _sellPrice);
//    }

    function forward(uint _toId, bytes data) onlyAuthorized() returns (bool) {
        if (!otherContracts[_toId].call(data)) {
            throw;
        }
        return true;
    }

    function reissueAsset(uint _id, bytes32 symbol, uint _value, address _locAddr) multisig returns (bool) {
        if(contracts[_id] != 0x0) {
            address platform = ChronoBankAssetProxyInterface(contracts[_id]).chronoBankPlatform();
            if (platform != 0x0 && ChronoBankPlatformInterface(platform).isReissuable(symbol)) {
                uint issued = LOCInterface(_locAddr).getIssued();
                if(_value <= LOCInterface(_locAddr).getIssueLimit() - issued) {
                    if(ChronoBankPlatformInterface(platform).reissueAsset(symbol, _value)) {
                        address Mint = LOCInterface(_locAddr).getContractOwner();
                        Reissue(_value, _locAddr);
                        return ChronoMintInterface(Mint).call(bytes4(sha3("setLOCIssued(address,uint256)")), _locAddr, issued + _value);
                    }
                }
            }
        }
        return false;
    }

    function revokeAsset(uint _id, bytes32 symbol, uint _value, address _locAddr) multisig returns (bool) {
        if(contracts[_id] != 0x0) {
            address platform = ChronoBankAssetProxyInterface(contracts[_id]).chronoBankPlatform();
            if (platform != 0x0 && ChronoBankPlatformInterface(platform).isReissuable(symbol)) {
                uint issued = LOCInterface(_locAddr).getIssued();
                if(_value <= issued) {
                    if(ChronoBankPlatformInterface(platform).revokeAsset(symbol, _value)) {
                        address Mint = LOCInterface(_locAddr).getContractOwner();
                        Reissue(_value, _locAddr);
                        return ChronoMintInterface(Mint).call(bytes4(sha3("setLOCIssued(address,uint256)")), _locAddr, issued - _value);
                    }
                }
            }
        }
        return false;
    }

    function sendAsset(uint _id, address _to, uint _value) onlyAuthorized() returns (bool) {
        if(contracts[_id] != 0x0) {
            address assetProxy = contracts[_id];
            if(ChronoBankAssetProxyInterface(contracts[_id]).smbl() == 'LHT') {
                uint feePercent = FeeInterface(ChronoBankAssetProxyInterface(assetProxy).getLatestVersion()).feePercent();
                uint amount = (_value * 10000)/(10000 + feePercent);
                return ERC20Interface(assetProxy).transfer(_to, amount);
            }
            return ERC20Interface(assetProxy).transfer(_to, _value);
        }
        return false;
    }

    function getBalance(uint _id) constant returns (uint) {
        return ERC20Interface(contracts[_id]).balanceOf(this);
    }

    function getAddress(uint _id) constant returns (address) {
        return contracts[_id];
    }

    function setAddress(address value) multisig returns (uint) {
        return setAddressInt(value);
    }

    function setAddressInt(address value) internal returns (uint) {
        if (contractsId[value] == uint(0x0)) {
            ERC20Interface(value).totalSupply();
            contracts[contractsCounter] = value;
            contractsId[value] = contractsCounter;
            UpdateContract(value, contractsId[value]);
            return contractsCounter++;
        }
        return contractsId[value];
    }

    function changeAddress(address _from, address _to) multisig returns (bool) {
        if (contractsId[_from] != 0) {
            contracts[contractsId[_from]] = _to;
            contractsId[_to] = contractsId[_from];
            delete contractsId[_from];
            UpdateContract(_to, contractsId[_to]);
            return true;
        }
        return false;
    }

    function removeAddress(address value) multisig {
        if(contractsId[value] > 0) {
            removeAddr(contractsId[value]);
            UpdateContract(value, contractsId[value]);
            delete contractsId[value];
        }
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

    function setOtherAddress(address value) multisig returns (uint) {
        return setOtherAddressInt(value);
    }

    function setOtherAddressInt(address value) internal returns (uint) {
       if (otherContractsId[value] == uint(0x0)) {
           otherContracts[otherContractsCounter] = value;
           otherContractsId[value] = otherContractsCounter;
           UpdateOtherContract(value,otherContractsId[value]);
           return otherContractsCounter++;
       }
       return otherContractsId[value];
    }

    function changeOtherAddress(address _from, address _to) multisig returns (bool) {
        if (otherContractsId[_from] != 0) {
            otherContracts[otherContractsId[_from]] = _to;
            otherContractsId[_to] = otherContractsId[_from];
            delete otherContractsId[_from];
            UpdateOtherContract(_to, otherContractsId[_to]);
            return true;
        }
        return false;
    }

    function removeOtherAddress(address value) multisig {
        if(otherContractsId[value] > 0) {
            removeOtherAddr(otherContractsId[value]);
            UpdateOtherContract(value, otherContractsId[value]);
            delete otherContractsId[value];
        }
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
