// SPDX-License-Identifier: GPL-3.0
pragma solidity ^ 0.5.7;
//pragma experimental ABIEncoderV2; // To support string array return values for showValidators().
import "github.com/provable-things/ethereum-api/blob/master/provableAPI_0.5.sol";

// array of validators
//mapping of productID to validators
contract certificate is usingProvable {
    string[] validators; //address of validators
    address admin;
    uint256 public randomNumber; // Random number to be supplied by Provable oraclize.
    struct pRID_Val {
        string validator; //address of validator
        string productID;
        string productDescription;
        string IPFS_Hash;
        string Origin;
        string cert_IPFS_Hash;
        uint8 cert_Status; // 1 for approved 0 for denied.
        address public_blockchainAddress;
        
    }
    mapping(string => pRID_Val) public checkValidator;
    constructor () public payable {
        validators.push("0xEC5bF0F1DE02E5FC8FdE5ADEbe12bD4239535b7C");
        validators.push("0x136f79926505f76C3252a921937dd5AB18dED515");
        admin = msg.sender;
        // Provable interface implementations.
        // provable_setCustomGasPrice(10000000);
        // provable_setProof(proofType_Ledger);
    }
    //event to alert validator using his address(val) 
    event Validator_Alert(string productID, string productDescription, string IPFS_Hash, string Origin, string val, address requester, string farmerSig);
    event farmerAlert (string productID, string cert_Status);
    event message(string msg);
    event failed(string msg);
    event responseRecvd(string msg, bytes32 proofIDfromProvable);
       
    function applyForCert (string memory productID, string memory productDescription, string memory IPFS_Hash, string memory Origin, string memory farmerSig, address public_blockchainAddress) public returns(bool){
      require (bytes(checkValidator[productID].validator).length == 0 ," ProductID already exist "); //check if productid exist by checking if it has an address
       // storing product details in contract
       checkValidator[productID].productDescription = productDescription;
       checkValidator[productID].productID = productID;
       checkValidator[productID].IPFS_Hash = IPFS_Hash;
       checkValidator[productID].Origin = Origin; 
       checkValidator[productID].public_blockchainAddress = public_blockchainAddress;
       string memory selectedValidator = randomlySelectedValidator();
       checkValidator[productID].validator = selectedValidator; 
       emit Validator_Alert(productID, productDescription, IPFS_Hash, Origin, selectedValidator, public_blockchainAddress, farmerSig); //aert validator
       return true;
    }
   function validate(string memory productID, string memory cert_IPFS_Hash, uint8 cert_Status) public returns(bool){
       require (parseAddr(checkValidator[productID].validator) == msg.sender, "You're not the authorized validator.");
       checkValidator[productID].cert_IPFS_Hash = cert_IPFS_Hash; // storing cert_IPFS_Hashs in mapping
       checkValidator[productID].cert_Status = cert_Status; //storing cert_Status in mapping
       if (cert_Status == 1) {
            emit farmerAlert (productID, "Approved Product");
       }else{
           emit farmerAlert ( productID,"Prodcut Denied");
       }
       return true;
   }
    function randomlySelectedValidator() public returns(string memory){
        getRandomNumFromProvable(); // Call the random number generating function for Provable to handle the processes involved.
        uint256 validatorLoc = uint256(randomNumber % validators.length); // Ensure the output of this is less or equal to number of validators hence Modulo operation.
        return validators[validatorLoc]; // Return a specific validator based on the randomly computed location or position.
    }
    //function to add validator to the array of validators
    function addValidator (string memory validator) public returns(uint8){
        require(msg.sender == admin);
        validators.push(validator);
        return 1; 
    }
    //function to delete validator from list of validators
    function delValidator(string memory validator) public  returns(uint8){
        require (msg.sender == admin);
        removeByValue(validator);
        return 1;
    }
     function find(string memory addr) internal view returns(uint) {
        uint i = 0;
        while ( keccak256(abi.encodePacked(validators[i])) != keccak256(abi.encodePacked(addr))) {
            i++;
        }
        return i;
    }

    function removeByValue(string memory addr) internal {
        uint i = find(addr);
        removeByIndex(i);
    }

    function removeByIndex(uint i) internal {
        validators[i] = validators[validators.length -1];
        validators.pop();
    }
    
    // Following functions are based on Provable's documentation.
    
    // Function to get the random number from Provable oraclize.
    function getRandomNumFromProvable() payable public {
        uint numberOfBytes = 7;
        uint delay = 0;
        uint callbackGas = 200000;
        provable_newRandomDSQuery(delay, numberOfBytes, callbackGas);
        emit message("Query to Provable for random number sent, awaiting response...");
    }
    
    // Function to be called by Provable Oraclize.
    function __callback(bytes32 queryId, string memory result) public {
        require(msg.sender == provable_cbAddress());
        uint MaxRange = 2 ** (8 * 7); // Very, very large large.
        randomNumber = uint(keccak256(abi.encodePacked(result))) % MaxRange;
        emit responseRecvd("Response received from Provable with ID:", queryId);
    }
}