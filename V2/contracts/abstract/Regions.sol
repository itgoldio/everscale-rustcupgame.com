pragma ton - solidity = 0.58 .1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../structs/RegionStruct.sol";

abstract contract Regions {

    mapping(uint8 => RegionStruct) m_regions;

    function _addRegion(
        uint8 id,
        string regionName,
        uint8 vel
    ) internal {
        m_regions[id] = RegionStruct(
            regionName,
            vel
        );
    }

    function _removeRegion(uint8 id) internal {
        delete m_regions[id];
    }

    function getRegions() external view returns(mapping(uint8 => RegionStruct)) {
        return(m_regions);
    }

}