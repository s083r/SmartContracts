pragma solidity ^0.4.11;

import "./Managed.sol";
import "./ExchangeInterface.sol";
import "./OwnedInterface.sol";
import "./ContractsManagerInterface.sol";

/**
*  @title ContractsManager
*/
contract ContractsManager is Managed, ContractsManagerInterface {
    uint constant ERROR_CONTRACT_EXISTS = 10000;
    uint constant ERROR_CONTRACT_NOT_EXISTS = 10001;

    StorageInterface.AddressesSet contractsAddresses;
    StorageInterface.Bytes32AddressMapping contractsTypes;

    /**
    *  @dev Contract metadata struct
    */
    struct ContractMetadata {
        address contractAddr;
        bytes32 tp;
    }

    event LogAddContract(address indexed contractAddress, bytes32 t);
    event LogContractAddressChange(address indexed contractAddress, bytes32 t);
    event Error(address indexed self, uint errorCode);

    /**
    *  @notice Constructor that sets `storage` and `crate` to given values.
    */
    function ContractsManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        contractsAddresses.init('contracts');
        contractsTypes.init('contractTypes');
    }

    /**
    *  @notice Initializes Contract Manager instance.
    *  @dev Contract must be initilized before first usage.
    *
    *  @return result code, 1 if success, otherwise error code
    */
    function init() returns (uint) {
        store.set(contractsManager,this);
        return OK;
    }

    /**
    *   @dev Returns an array containing all contracts addresses.
    *   @return Array of token addresses.
    */
    function getContractAddresses() constant returns (address[]) {
        return store.get(contractsAddresses);
    }

    /**
    *   @dev Returns a contracts address by given type.
    *   @return contractAddress
    */
    function getContractAddressByType(bytes32 _type) constant returns (address contractAddress) {
        return store.get(contractsTypes, _type);
    }

    /**
    *  @dev Allow owner to add new contract
    *
    *  @param _contract contacts address
    *  @param _type contracts type
    *
    *  @return result code, 1 if success, otherwise error code
    *  TODO: AG UNAUTHORIZED ACCESS
    */
    function addContract(address _contract, bytes32 _type) returns (uint) {
        if (isExists(_contract)) {
            return emitError(ERROR_CONTRACT_EXISTS);
        }

        store.add(contractsAddresses, _contract);
        store.set(contractsTypes, _type, _contract);

        LogAddContract(_contract, _type);
        return OK;
    }

    /**
    *   @dev Allows owner to modify an existing contract's address.
    *   @param _type Type of contract.
    *   @param _newAddr New address of contract.
    *
    *  @return result code, 1 if success, otherwise error code
    */
    function setContractAddress(address _newAddr, bytes32 _type) onlyAuthorized() returns (uint) {
        if (isExists(_newAddr)) {
            return emitError(ERROR_CONTRACT_EXISTS);
        }

        store.set(contractsTypes, _type, _newAddr);
        store.set(contractsAddresses, store.get(contractsTypes, _type), _newAddr);

        LogContractAddressChange(_newAddr, _type);
        return OK;
    }

    /**
    *  @dev Tells whether a contract wit a given address exists.
    *
    *  @return `true` if a contract has been registers, otherwise `false`
    */
    function isExists(address _contract) private constant returns (bool) {
        return store.includes(contractsAddresses, _contract);
    }

    /**
    *  @dev Util function which throws error event with a given error
    */
    function emitError(uint e) private returns (uint)  {
        Error(msg.sender, e);
        return e;
    }

    /**
    *  Default fallback function.
    */
    function() {
        throw;
    }
}
