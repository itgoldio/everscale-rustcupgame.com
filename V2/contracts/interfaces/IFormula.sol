pragma ton-solidity = 0.58.1;

import "../structs/RegionStruct.sol";

interface IFormula {
    function calculate(
        RegionStruct region,
        uint8 playersCount,
        uint8[] speed,
        uint8[] acceleration,
        uint8[] braking,
        uint8[] control,
        uint8 lastVel,
        uint8 random,
        uint8 regionNumber,
        bool isLastRegion
    ) external responsible view returns(
        uint256[] totalPoints,
        uint8 currentVel,
        bool[] controlLosses,
        uint8 currentRegionNumber
    );
}