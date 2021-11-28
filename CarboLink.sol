// SPDX-License-Identifier: Copyright
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract CarboLink is ChainlinkClient {

    /**
     * Smart Contract Constructor
     * --------------------------
     *
     * @param sentence A sentence to increase contract's security
     * @param oracleAddress The address of the used oracle service
     * @param oracleFee The value of the fee to pay, calculate with
     * @param oracleJobId The Id of the oracle job to use
     */
    constructor(string memory sentence,
                address oracleAddress,
                uint256 oracleFee,
                bytes32 oracleJobId)
                payable {

        rootUser = payable(msg.sender);
        rootKey = keccak256(abi.encodePacked(sentence));
        setChainlinkToken(rootUser);
        setChainlinkOracle(oracleAddress);
        _oracleFee = oracleFee;
        _oracleJobId = oracleJobId;

    }

    /**
     * Raw data manipulation of parentDevices
     * ======================================
     *
     * CREATE
     * ------
     */

    function addParentDevice(string calldata message,
                             string calldata name, uint8 status,
                             uint8 consumptionType,
                             uint defaultCPU) onlyAdmin(message)
                             external {
        
        parentDevices.push(ParentDevice(name, status,
                           consumptionType, defaultCPU));

    }

    /**
     * READ
     * ----
     */

    function getParentDeviceById(uint id)
                                    onlyExistingParentDevice(id)
                                    external view returns
                                    (ParentDevice memory) {

        require(id < parentDevices.length, 'Invalid device Id.');
        return parentDevices[id];

    }

    function getParentDevices() external view
                                returns (ParentDevice[] memory) {

        return parentDevices;

    }

    /**
     * UPDATE
     * ------
     */

    function changeParentDevice(string calldata message, uint id,
                                string calldata name, uint8 status,
                                uint8 consumptionType, uint defaultCPU)
                                onlyAdmin(message)
                                onlyExistingParentDevice(id) external {

        parentDevices[id].name = name;
        parentDevices[id].status = status;
        parentDevices[id].consumptionType = consumptionType;
        parentDevices[id].defaultCPU = defaultCPU;

    }

    /**
     * DELETE
     * ------
     */

    // NOT AVAILABLE.

    /**
     * Raw data manipulation of userDevices
     * ====================================
     *
     * CREATE
     * ------
     */

    function addUserDevice(string calldata customName,
                           uint customCPU,
                           uint parentDeviceId)
                           onlyExistingParentDevice(parentDeviceId)
                           external {
        
        userDevices[msg.sender].push(UserDevice(customName,
                                                customCPU,
                                                parentDeviceId));

    }

    /**
     * READ
     * ----
     */

    function getUserDevices() external view
                              returns (UserDevice[] memory) {

        return userDevices[msg.sender];

    }

    /**
     * UPDATE
     * ------
     */

    function changeUserDevice(uint id,
                              string calldata customName,
                              uint customCPU,
                              uint parentDeviceId)
                              onlyExistingUserDevice(id)
                              onlyExistingParentDevice(parentDeviceId)
                              external {
        
        userDevices[msg.sender][id].customName = customName;
        userDevices[msg.sender][id].customCPU = customCPU;
        userDevices[msg.sender][id].parentDeviceId = parentDeviceId;

    }

    /**
     * DELETE
     * ------
     */

    // NOT AVAILABLE.

    /**
     * Raw data manipulation of timeMeasures
     * =====================================
     *
     * CREATE
     * ------
     */

    function startTimeMeasure(uint userDeviceId)
                             onlyExistingUserDevice(userDeviceId)
                             external {

        timeMeasures[msg.sender].push(TimeMeasure(block.timestamp, 0, userDeviceId));

    }

    /**
     * READ
     * ----
     */

    function getTimeMeasures() external view
                               returns (TimeMeasure[] memory) {

        return timeMeasures[msg.sender];

    }

    /**
     * UPDATE
     * ------
     */

    function stopTimeMeasure(uint measureId)
                             onlyLivingTimeMeasure(measureId)
                             external payable {
    
        require(msg.value >= MEASURE_FEE,
                'Cannot stop measure without fee.');
        timeMeasures[msg.sender][measureId].stop = block.timestamp;

    }

    /**
     * DELETE
     * ------
     */

    // NOT AVAILABLE.

    /**
     * Raw data manipulation of unitMeasures
     * =====================================
     *
     * CREATE
     * ------
     */

    function addUnitMeasure(uint unitCount, uint userDeviceId)
                            onlyEnoughFee()
                            external payable {

        unitMeasures[msg.sender].push(UnitMeasure(block.timestamp,
                                                  unitCount,
                                                  userDeviceId));

    }

    /**
     * READ
     * ----
     */

    function getUnitMeasures() external view
                               returns (UnitMeasure[] memory) {

        return unitMeasures[msg.sender];

    }

    /**
     * UPDATE
     * ------
     */

    // NOT AVAILABLE.

    /**
     * DELETE
     * ------
     */

    // NOT AVAILABLE.

    /**
     * Raw data manipulation of userCountries
     * ======================================
     *
     * CREATE
     * ------
     */

    function addUserCountry(string calldata countryCode) 
                            onlyValidCountryCode(countryCode)
                            external {

        userCountries[msg.sender] = countryCode;

    }

    /**
     * READ
     * ----
     */

    function getUserCountry() external view
                              returns (string memory) {

        return userCountries[msg.sender];

    }

    /**
     * UPDATE
     * ------
     */

    function changeUserCountry(string calldata newCountryCode)
                               onlyValidCountryCode(newCountryCode)
                               external {

        userCountries[msg.sender] = newCountryCode;

    }

    /**
     * DELETE
     * ------
     */

    function deleteUserCountry() external {
    
        userCountries[msg.sender] = '';
    
    }

    /**
     * API FUNCTIONS
     * =============
     */

    function getCost() external {

        require(validateCountryCode(userCountries[msg.sender]),
                '2 letter country codes are supported.');
        makeApiRequest('getCostByCountryCode',
                       userCountries[msg.sender]);

    }

    function getCost(string calldata countryCode)
                     onlyValidCountryCode(countryCode)
                     external {

        makeApiRequest('getCostByCountryCode', countryCode);

    }

    function getSourceRates() external {

        require(validateCountryCode(userCountries[msg.sender]),
                '2 letter country codes are supported.');
        makeApiRequest('getSourceRatesByCountryCode',
                       userCountries[msg.sender]);

    }

    function getSourceRates(string calldata countryCode)
                            onlyValidCountryCode(countryCode)
                            external {

        makeApiRequest('getSourceRatesByCountryCode',
                       countryCode);

    }

    function fullfill(bytes32 _requestId, bytes calldata _data)
                      recordChainlinkFulfillment(_requestId)
                      public {

        emit ApiResponseReceived(_data);

    }

    /**
     * INTERNAL FUNCTIONS
     * ==================
     */

    // Source: https://gist.github.com/alexroan/a8caf258218f4065894ecd8926de39e7
    function bytes32ToString(bytes32 _bytes32)
                            public pure returns (string memory) {
        
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);

    }

    function makeApiRequest(string memory endpoint,
                            string memory countryCode)
                            internal {

        
        string memory apiEndpoint = string(abi.encodePacked(API_BASE,
                                                            endpoint,
                                                            '/',
                                                            countryCode));
        Chainlink.Request memory request = buildChainlinkRequest(_oracleJobId,
                                                                 address(this),
                                                                 this.fullfill.selector);
        request.add('get', apiEndpoint);
        sendChainlinkRequest(request, _oracleFee);

    }
    
    // Source: https://gist.github.com/alexroan/a8caf258218f4065894ecd8926de39e7
    function stringToBytes32(string memory source)
                             public pure returns (bytes32 result) {

        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }

    }

    function validateCountryCode(string memory code)
                                 pure internal
                                 returns (bool) {

        return bytes(code).length == 2;

    }

    /**
     * MODIFIERS
     * =========
     */

    /**
     * Modifier to optimize code if checking admin credentials
     * -------------------------------------------------------
     *
     * @param sentence Admin credentials
     */
    modifier onlyAdmin(string memory sentence) {

        require(msg.sender == rootUser, 'Authorization required!');
        require(keccak256(abi.encodePacked(sentence)) == rootKey,
                'Authorization key required!');
        _;

    }

    modifier onlyEnoughFee() {

        require(msg.value >= MEASURE_FEE,
                'Cannot stop measure without fee.');
        _;

    }

    modifier onlyExistingParentDevice(uint id) {

        require(id < parentDevices.length,
                'Invalid parent device Id.');
        _;

    }

    modifier onlyExistingUserDevice(uint id) {

        require(id < userDevices[msg.sender].length,
                'Invalid user device Id.');
        _;

    }

    modifier onlyLivingTimeMeasure(uint id) {

        require(id < timeMeasures[msg.sender].length,
                'Invalid time measure Id.');
        require(timeMeasures[msg.sender][id].stop == 0,
                'Cannot stop a halted time measure.');
        _;

    }

    modifier onlyValidCountryCode(string calldata code) {

        require(validateCountryCode(code),
                '2 letter country codes are supported.');
        _;

    }

    /**
     * STRUCT DEFINITIONS
     * ==================
     */

    struct ParentDevice {
        string name;
        uint8 status;
        uint16 consumptionType;
        uint defaultCPU;
    }

    struct UserDevice {
        string customName;
        uint customCPU;
        uint parentDeviceId;
    }
    
    struct TimeMeasure {
        uint256 start;
        uint256 stop;
        uint userDeviceId;
    }

    struct UnitMeasure {
        uint256 when;
        uint unitCount;
        uint userDeviceId;
    }

     /**
     * PUBLIC CONSTANTS
     * ================
     */

    string constant public API_BASE = 'http://hyperrixel.com/hackathon/carbolink/api/';
    uint256 constant public MEASURE_FEE = 100;

   /**
     * STATE VARIABLES
     * ===============
     */

    // Admin credentials
    uint256 private _oracleFee;
    bytes32 private _oracleJobId;
    address payable private rootUser;
    bytes32 private rootKey;

    // Public variables
    ParentDevice[] public parentDevices;
    mapping (address => TimeMeasure[]) public timeMeasures;
    mapping (address => UnitMeasure[]) public unitMeasures;
    mapping (address => string) public userCountries;
    mapping (address => UserDevice[]) public userDevices;

   /**
     * EVENTS
     * ======
     */

    event ApiResponseReceived(bytes data);

   /**
     * USING DIRECTIVES
     * ================
     */

    using Chainlink for Chainlink.Request;
    
}