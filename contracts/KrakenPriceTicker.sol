/*
   Universal price ticker

   This contract keeps in storage an updated Token price,
   which is updated every ~60 seconds.
*/

pragma solidity ^0.4.11;
import "oraclize/usingOraclize.sol";
import "./Managed.sol";
import "./Owned.sol";

contract KrakenPriceTicker is usingOraclize, Owned {

    address delegate;

    string public rate;
    string public url;  // for example "https://api.kraken.com/0/public/Ticker?pair=ETHXBT";
    string public formater; //for example "result.XETHXXBT.c.0";
    uint public interval = 1;

    event newOraclizeQuery(string description);
    event newKrakenPriceTicker(string price);

    function init(bool _dev, string _url, string _formater) {
        if(_dev)
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        url = _url;
        formater = _formater;
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        //update();
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
        rate = result;
        newKrakenPriceTicker(rate);
        //update();
    }

    function setURL(string _url) onlyContractOwner returns(bool) {
        url = _url;
        return true;
    }

    function setFormater(string _formater) onlyContractOwner returns(bool) {
        formater = _formater;
        return true;
    }

    function setInterval(uint _interval) onlyContractOwner  returns(bool) {
        interval = _interval;
        return true;
    }

    function update() payable {
        if (oraclize.getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(interval, "URL", strConcat("json(",url,").",formater));
        }
    }

}
