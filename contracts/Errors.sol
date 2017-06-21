pragma solidity ^0.4.11;

/**
*   @title Provides a basic erros codes
*/
library Errors {
  /**
  *  Error list
  */
  enum E {
    UNAUTHORIZED,
    OK,

    MULTISIG_ADDED,

    // LOC errors
    LOC_NOT_FOUND,
    LOC_EXISTS,
    LOC_INACTIVE,
    LOC_SHOULD_NO_BE_ACTIVE,
    LOC_INVALID_PARAMETER,
    LOC_INVALID_INVOCATION,
    LOC_ADD_CONTRACT,
    LOC_SEND_ASSET,
    LOC_REQUESTED_ISSUE_VALUE_EXCEEDED,
    LOC_REISSUING_ASSET_FAILED,
    LOC_REQUESTED_REVOKE_VALUE_EXCEEDED,
    LOC_REVOKING_ASSET_FAILED,

    // User Manager errors
    USER_NOT_FOUND,
    USER_INVALID_PARAMETER,
    USER_ALREADY_CBE,
    USER_NOT_CBE,
    USER_SAME_HASH,
    USER_INVALID_REQURED,
    USER_INVALID_STATE,

    // Crowdfunding Manager errors
    CROWDFUNDING_INVALID_INVOCATION,
    CROWDFUNDING_ADD_CONTRACT,
    CROWDFUNDING_NOT_ASSET_OWNER,

    // Pending Manager errors
    PENDING_NOT_FOUND,
    PENDING_INVALID_INVOCATION,
    PENDING_ADD_CONTRACT,
    PENDING_DUPLICATE_TX,
    PENDING_CANNOT_CONFIRM,
    PENDING_PREVIOUSLY_CONFIRMED,
    PENDING_NOT_ENOUGH_CONFIRMED,

    // Storage Manager errors
    STORAGE_INVALID_INVOCATION,

    // Exchange errors
    EXCHANGE_INVALID_PARAMETER,
    EXCHANGE_INVALID_INVOCATION,
    EXCHANGE_INVALID_FEE_PERCENT,
    EXCHANGE_INVALID_PRICE,
    EXCHANGE_MAINTENANCE_MODE,
    EXCHANGE_TOO_HIGH_PRICE,
    EXCHANGE_TOO_LOW_PRICE,
    EXCHANGE_INSUFFICIENT_BALANCE,
    EXCHANGE_INSUFFICIENT_ETHER_SUPPLY,
    EXCHANGE_PAYMENT_FAILED,
    EXCHANGE_TRANSFER_FAILED,
    EXCHANGE_FEE_TRANSFER_FAILED,

    // Exchange Manager errors
    EXCHANGE_STOCK_NOT_FOUND,
    EXCHANGE_STOCK_INVALID_PARAMETER,
    EXCHANGE_STOCK_INVALID_INVOCATION,
    EXCHANGE_STOCK_ADD_CONTRACT,
    EXCHANGE_STOCK_UNABLE_CREATE_EXCHANGE,

    // Vote errors
    VOTE_INVALID_PARAMETER,
    VOTE_INVALID_INVOCATION,
    VOTE_ADD_CONTRACT,
    VOTE_LIMIT_EXCEEDED,
    VOTE_POLL_LIMIT_REACHED,
    VOTE_POLL_WRONG_STATUS,
    VOTE_POLL_INACTIVE,
    VOTE_POLL_NO_SHARES,
    VOTE_POLL_ALREADY_VOTED,
    VOTE_ACTIVE_POLL_LIMIT_REACHED,
    VOTE_UNABLE_TO_ACTIVATE_POLL,

    REWARD_NOT_FOUND,
    REWARD_INVALID_PARAMETER,
    REWARD_INVALID_INVOCATION,
    REWARD_INVALID_STATE,
    REWARD_INVALID_PERIOD,
    REWARD_NO_REWARDS_LEFT,
    REWARD_ASSET_TRANSFER_FAILED,
    REWARD_ALREADY_CALCULATED,
    REWARD_CALCULATION_FAILED,
    REWARD_CANNOT_CLOSE_PERIOD,
    REWARD_ASSET_ALREADY_REGISTERED,

    // Contract Manager Errors
    CONTRACT_EXISTS,
    CONTRACT_NOT_EXISTS,

    TIMEHOLDER_ALREADY_ADDED,
    TIMEHOLDER_INVALID_INVOCATION,
    TIMEHOLDER_INVALID_STATE,
    TIMEHOLDER_TRANSFER_FAILED,
    TIMEHOLDER_WITHDRAWN_FAILED,
    TIMEHOLDER_DEPOSIT_FAILED,
    TIMEHOLDER_INSUFFICIENT_BALANCE,

    ERCMANAGER_INVALID_INVOCATION,
    ERCMANAGER_INVALID_STATE,
    ERCMANAGER_TOKEN_SYMBOL_NOT_EXISTS,
    ERCMANAGER_TOKEN_NOT_EXISTS,
    ERCMANAGER_TOKEN_SYMBOL_ALREADY_EXISTS,
    ERCMANAGER_TOKEN_ALREADY_EXISTS,
    ERCMANAGER_TOKEN_UNCHANGED,

    // Assets Manager errors
    ASSETS_INVALID_INVOCATION,
    ASSETS_EXISTS,
    ASSETS_TOKEN_EXISTS,
    ASSETS_CANNON_CLAIM_PLATFORM_OWNERSHIP,
    ASSETS_WRONG_PLATFORM,
    ASSETS_NOT_A_PROXY,
    ASSETS_OWNER_ONLY,
    ASSETS_CANNOT_ADD_TO_REGISTRY
  }

    /**
    *  Retuns numeric error code of given `error`
    *
    *  @param error is an error object
    *  @return error code numeric representation of given `error`
    */
    function code(E error) internal constant returns (uint) {
        if (error == E.OK) {
            return 1;
        }
        else if (error == E.UNAUTHORIZED) {
            return 0;
        }
        else if (error == E.MULTISIG_ADDED) {
            return 3;
        }
        else if (uint(error) >= uint(E.LOC_NOT_FOUND) && uint(error) <= uint(E.LOC_REVOKING_ASSET_FAILED)) {
            return 1000 + uint(error) - uint(E.LOC_NOT_FOUND);
        }
        else if (uint(error) >= uint(E.USER_NOT_FOUND) && uint(error) <= uint(E.USER_INVALID_REQURED)) {
            return 2000 + uint(error) - uint(E.USER_NOT_FOUND);
        }
        else if (uint(error) >= uint(E.CROWDFUNDING_INVALID_INVOCATION) && uint(error) <= uint(E.CROWDFUNDING_NOT_ASSET_OWNER)) {
            return 3000 + uint(error) - uint(E.CROWDFUNDING_INVALID_INVOCATION);
        }
        else if (uint(error) >= uint(E.PENDING_NOT_FOUND) && uint(error) <= uint(E.PENDING_NOT_ENOUGH_CONFIRMED)) {
            return 4000 + uint(error) - uint(E.PENDING_NOT_FOUND);
        }
        else if (uint(error) >= uint(E.STORAGE_INVALID_INVOCATION) && uint(error) <= uint(E.STORAGE_INVALID_INVOCATION)) {
            return 5000 + uint(error) - uint(E.STORAGE_INVALID_INVOCATION);
        }
        else if (uint(error) >= uint(E.EXCHANGE_INVALID_PARAMETER) && uint(error) <= uint(E.EXCHANGE_FEE_TRANSFER_FAILED)) {
            return 6000 + uint(error) - uint(E.EXCHANGE_INVALID_PARAMETER);
        }
        else if (uint(error) >= uint(E.EXCHANGE_STOCK_NOT_FOUND) && uint(error) <= uint(E.EXCHANGE_STOCK_UNABLE_CREATE_EXCHANGE)) {
            return 7000 + uint(error) - uint(E.EXCHANGE_STOCK_NOT_FOUND);
        }
        else if (uint(error) >= uint(E.VOTE_INVALID_PARAMETER) && uint(error) <= uint(E.VOTE_UNABLE_TO_ACTIVATE_POLL)) {
            return 8000 + uint(error) - uint(E.VOTE_INVALID_PARAMETER);
        }
        else if (uint(error) >= uint(E.REWARD_NOT_FOUND) && uint(error) <= uint(E.REWARD_ASSET_ALREADY_REGISTERED)) {
            return 9000 + uint(error) - uint(E.REWARD_NOT_FOUND);
        }
        else if (uint(error) >= uint(E.CONTRACT_EXISTS) && uint(error) <= uint(E.CONTRACT_NOT_EXISTS)) {
            return 10000 + uint(error) - uint(E.CONTRACT_EXISTS);
        }
        else if (uint(error) >= uint(E.ASSETS_INVALID_INVOCATION) && uint(error) <= uint(E.ASSETS_CANNOT_ADD_TO_REGISTRY)) {
            return 11000 + uint(error) - uint(E.ASSETS_INVALID_INVOCATION);
        }
        else if (uint(error) >= uint(E.TIMEHOLDER_ALREADY_ADDED) && uint(error) <= uint(E.TIMEHOLDER_INSUFFICIENT_BALANCE)) {
            return 12000 + uint(error) - uint(E.TIMEHOLDER_ALREADY_ADDED);
        }
        else if (uint(error) >= uint(E.ERCMANAGER_INVALID_INVOCATION) && uint(error) <= uint(E.ERCMANAGER_TOKEN_UNCHANGED)) {
            return 13000 + uint(error) - uint(E.ERCMANAGER_INVALID_INVOCATION);
        }
        else {
            return 0xDEFDEFDEF;
        }
    }
}
