pragma solidity ^0.4.8;

import "./Managed.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ERC20Interface.sol";
import "./ExchangeInterface.sol";

contract ContractsManager is Managed {
  address internal platform;
  uint contractsCounter;
  uint otherContractsCounter;
  mapping(uint => address) internal contracts;
  mapping(uint => address) internal othercontracts;
  mapping(address => uint) internal contractsId;
  mapping(address => uint) internal othercontractsId;
  event updateContract(address contractAddress);
  event updateOtherContract(address contractAddress);

  function ContractsManager(address _tpc, address _rc, address _ec, address _lhpc)
  {
      contracts[contractsCounter] = _tpc;
      contractsId[_tpc] = contractsCounter;
      contractsCounter++;
      contracts[contractsCounter] = _lhpc;
      contractsId[_lhpc] = contractsCounter;
      contractsCounter++;
      othercontracts[otherContractsCounter] = _rc;
      othercontractsId[_rc] = otherContractsCounter;
      otherContractsCounter++;
      othercontracts[otherContractsCounter] = _ec;
      othercontractsId[_ec] = otherContractsCounter;
      otherContractsCounter++;
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
       othercontracts[1] = _addr;
       return true;
     }
     return false;
  }

  function setExchangePrices(uint _buyPrice, uint _sellPrice) onlyAuthorized() returns(bool) {
     return ExchangeInterface(othercontracts[1]).setPrices(_buyPrice, _sellPrice);
  }

  function reissueAsset(bytes32 _symbol, uint _value) onlyAuthorized() returns(bool) {
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
    contracts[contractsCounter] = value;
    contractsId[value] = contractsCounter;
    updateContract(value);
    return contractsCounter++;
  }

  function removeAddress(address value) onlyAuthorized() execute(Operations.editMint) {
    removeAddr(contractsId[value]);
    updateContract(value);
  }

  function removeAddr(uint i) {
        if (i >= contractsCounter) return;

        for (; i<contractsCounter-1; i++){
            contracts[i] = contracts[i+1];
        }
        contractsCounter--;
    }

  function getOtherAddress(uint _id) constant returns(address) {
    return othercontracts[_id];
  }

  function setOtherAddress(address value) onlyAuthorized() execute(Operations.editMint) {
    othercontracts[contractsCounter] = value;
    othercontractsId[value] = otherContractsCounter;
    updateOtherContract(value);
    otherContractsCounter++;
  }

  function removeOtherAddress(address value) onlyAuthorized() execute(Operations.editMint) {
    removeOtherAddr(othercontractsId[value]);
    updateOtherContract(value);
  }

  function removeOtherAddr(uint i) {
        if (i >= otherContractsCounter) return;

        for (; i<otherContractsCounter-1; i++){
            othercontracts[i] = othercontracts[i+1];
        }
        otherContractsCounter--;
    }
}
