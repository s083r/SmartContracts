/*
   Universal price ticker

   This contract keeps in storage an updated Token price,
   which is updated every ~60 seconds.
*/

pragma solidity ^0.4.11;
import "oraclize/usingOraclize.sol";
import "./Managed.sol";

contract KrakenPriceTicker is usingOraclize,Managed {
    
    string public rate;
    string public url = "https://api.kraken.com/0/public/Ticker?pair=ETHXBT";
    string public formater = "result.XETHXXBT.c.0";
    uint public interval = 1;
    
    event newOraclizeQuery(string description);
    event newKrakenPriceTicker(string price);
    

    function KrakenPriceTicker(bool _dev) {
        if(_dev)
          OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update();
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
        rate = result;
        newKrakenPriceTicker(rate);
        update();
    }

    function setURL(string _url) onlyAuthorized returns(bool) {
       url = _url;
       return true;
    }

    function setFormater(string _formater) onlyAuthorized returns(bool) {
       formater = _formater;
       return true;
    }

    function setInterval(uint _interval) onlyAuthorized returns(bool) {
       interval = _interval;
       return true;
    }

        /**
          * Accept all ether to maintain exchange supply.
         */
    function () payable {}
    
    function update() payable {
        if (oraclize.getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(interval, "URL", strConcat("json(",url,").",formater));
        }
    }
    
} 
