pragma solidity ^0.4.8;

import {PendingManagerInterface as Shareable} from "./PendingManagerInterface.sol";
import "./UserManagerInterface.sol";
import "./ContractsManagerInterface.sol";
import "./StorageAdapter.sol";
import "./Errors.sol";

contract Managed is StorageAdapter {

    StorageInterface.Address contractsManager;

    function Managed() {
        contractsManager.init('contractsManager');
    }

    function getContractsManager() constant returns(address) {
        return store.get(contractsManager);
    }

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier onlyAuthorizedContract(address key) {
        if (isAuthorized(key)) {
            _;
        }
    }

    function multisig() internal returns (Errors.E e) {
        address shareable = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.PendingManager);
        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data);
            e = Shareable(shareable).addTx(_r, msg.data, this, msg.sender);

            return (e == Errors.E.OK) ? Errors.E.MULTISIG_ADDED : e;
        }

        return Errors.E.OK;
    }

    function isAuthorized(address key) constant returns (bool) {
        address userManager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.UserManager);
        return UserManagerInterface(userManager).getCBE(key);
    }

}
