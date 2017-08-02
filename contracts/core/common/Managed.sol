pragma solidity ^0.4.11;

import "./Object.sol";
import {PendingManagerInterface as Shareable} from "../../pending/PendingManagerInterface.sol";
import "../user/UserManagerInterface.sol";
import "../contracts/ContractsManagerInterface.sol";
import "../storage/StorageAdapter.sol";

contract Managed is StorageAdapter, Object {
    address public contractsManager;

    uint constant UNAUTHORIZED = 0;
    uint constant MULTISIG_ADDED = 3;
    uint constant INTERNAL_ERROR = 4;

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier onlyAuthorizedContract(address key) {
        if (isAuthorized(key) || msg.sender == lookupManager("PendingManager")) {
            _;
        }
    }

    function Managed(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
    }

    /**
    *  @dev Setter for ContractsManager. Force overrides currect manager.
    *
    *  @param _contractsManager contracts manager. 0x0 is not allowed.
    */
    function setContractsManager(address _contractsManager) onlyContractOwner {
        contractsManager = _contractsManager;
    }

    /**
    *  @notice Will crash if no manager in the system with given identifier.
    *
    *  @dev Returns manager's address by its identifier (type).
    *
    *  @param _identifier is a manager's identifier. 0x0 is not allowed.
    */
    function lookupManager(bytes32 _identifier) constant returns (address manager) {
        manager =  ContractsManagerInterface(contractsManager).getContractAddressByType(_identifier);

        // invalid identifier or initialization error. no way to continue.
        require(manager != 0x0);
    }

    function isAuthorized(address key) constant returns (bool) {
        address userManager = lookupManager("UserManager");
        return UserManagerInterface(userManager).getCBE(key);
    }

    function multisig() internal returns (uint errorCode) {
        address shareable = lookupManager("PendingManager");

        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data);
            errorCode = Shareable(shareable).addTx(_r, msg.data, this, msg.sender);

            return (errorCode == OK) ? MULTISIG_ADDED : errorCode;
        }

        return OK;
    }
}
