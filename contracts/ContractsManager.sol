pragma solidity ^0.4.8;

import "./Managed.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ERC20Interface.sol";
import "./ExchangeInterface.sol";

contract ContractsManager is Managed {
  address internal platform;
  uint public contractsCounter = 1;
  uint public otherContractsCounter = 1;
  mapping(uint => address) internal contracts;
  mapping(uint => address) internal othercontracts;
  mapping(address => uint) internal contractsId;
  mapping(address => uint) internal othercontractsId;
  event updateContract(address contractAddress);
  event updateOtherContract(address contractAddress);

 function getAssetBalances(bytes32 _symbol, uint _startId, uint _num) constant returns(address[] result,uint[] result2) {
   if(_num <= 100) {
    result = new address[](_num);
    result2 = new uint[](_num);
    for(uint i = 0; i < _num; i++)
    {
       address owner = ChronoBankPlatformInterface(platform)._address(_startId);
       uint balance = ChronoBankPlatformInterface(platform)._balanceOf(_startId,_symbol);
       result[i] = owner;
       result2[i] = balance;
       _startId++;
     }
     return (result,result2);
   }
   throw;
  }

  function getContracts() constant returns(address[] result) {
  result = new address[](contractsCounter-1);
  for(uint i=0; i<contractsCounter-1;i++) {
    result[i] = contracts[i+1];
  } 
  return result;
  }

  function getOtherContracts() constant returns(address[] result) {
  result = new address[](otherContractsCounter-1);
  for(uint i=0; i<otherContractsCounter-1;i++) {
    result[i] = othercontracts[i+1];
  }
  return result;
  }

  function claimPlatformOwnership(address _addr) onlyAuthorized() returns(bool) {
     if(Owned(_addr).claimContractOwnership()) {
       platform = _addr;
       return true;
     }
     return false;
  }

  function claimExchangeOwnership(address _addr) onlyAuthorized() returns(bool) {
     if(Owned(_addr).claimContractOwnership()) {
       setOtherAddress(_addr);
       return true;
     }
     return false;
  }

  function setExchangePrices(uint _buyPrice, uint _sellPrice) onlyAuthorized() returns(bool) {
     return ExchangeInterface(othercontracts[1]).setPrices(_buyPrice, _sellPrice);
  }

  function reissueAsset(bytes32 _symbol, uint _value) onlyAuthorized() execute(Operations.editMint) returns(bool) {
     if(platform != 0x0) {
        return ChronoBankPlatformInterface(platform).reissueAsset(_symbol, _value);
     }
     return false;
  }

  function sendAsset(uint _id, address _to, uint _value) onlyAuthorized() returns(bool) {
     return ERC20Interface(contracts[_id]).transfer(_to,_value);
  }

  function getBalance(uint _id) constant returns(uint) {
     return ERC20Interface(contracts[_id]).balanceOf(this);
  }

  function getAddress(uint _id) constant returns(address) {
    return contracts[_id];
  }

  function setAddress(address value) onlyAuthorized() execute(Operations.editMint) returns(uint) {
    if(contractsId[value] == 0) {
      contracts[contractsCounter] = value;
      contractsId[value] = contractsCounter;
      updateContract(value);
      return contractsCounter++;
    }
    return contractsId[value];
  }

  function removeAddress(address value) onlyAuthorized() execute(Operations.editMint) {
    removeAddr(contractsId[value]);
    delete contractsId[value];
    updateContract(value);
  }

  function removeAddr(uint i) {
        if (i >= contractsCounter) return;

        for (; i<contractsCounter; i++){
            contracts[i] = contracts[i+1];
        }
	delete contracts[i+1];
        contractsCounter--;
    }

  function getOtherAddress(uint _id) constant returns(address) {
    return othercontracts[_id];
  }

  function setOtherAddress(address value) onlyAuthorized() execute(Operations.editMint) returns (uint) {
    if(othercontractsId[value] == 0) {
      othercontracts[otherContractsCounter] = value;
      othercontractsId[value] = otherContractsCounter;
      updateOtherContract(value);
      otherContractsCounter++;
      return otherContractsCounter; 
    }
    return othercontractsId[value];
  }

  function removeOtherAddress(address value) onlyAuthorized() execute(Operations.editMint) {
    removeOtherAddr(othercontractsId[value]);
    updateOtherContract(value);
  }

  function removeOtherAddr(uint i) {
        if (i >= otherContractsCounter) return;

        for (; i<otherContractsCounter; i++){
            othercontracts[i] = othercontracts[i+1];
        }
        otherContractsCounter--;
    }
}
