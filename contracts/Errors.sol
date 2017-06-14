pragma solidity ^0.4.11;

/**
*   @title Provides a basic erros codes
*/
library Errors {
  /**
  * TODO
  */
  enum E {
    OK,

    // LOC errors
    LOC_NOT_FOUND,
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
    USER_INVALID_REQURED
  }

  /**
  * TODO
  */
  function code(E error) internal constant returns (uint) {
      if (error == E.OK) {
          return 0;
      } else if (uint(error) >= uint(E.LOC_NOT_FOUND) && uint(error) <= uint(E.LOC_REVOKING_ASSET_FAILED)) {
          return 1000 + uint(error) - uint(E.LOC_NOT_FOUND);
      } else if (uint(error) >= uint(E.USER_NOT_FOUND) && uint(error) <= uint(E.USER_INVALID_REQURED)) {
          return 2000 + uint(error) - uint(E.USER_NOT_FOUND);
      }
  }
}
