pragma ton - solidity = 0.58 .1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../structs/BoosterStruct.sol";

abstract contract Boosters {

    mapping(uint8 => BoosterStruct) m_boosters;

    function _addBooster(
        uint8 id,
        string _name,
        int8 _speedBooster,
        int8 _accelerationBooster,
        int8 _brakingBooster,
        int8 _controlBooster
    ) internal {
        m_boosters[id] = BoosterStruct(
            _name,
            _speedBooster,
            _accelerationBooster,
            _brakingBooster,
            _controlBooster
        );
    }

    function _removeBooster(uint8 id) internal {
        delete m_boosters[id];
    }

    function getBoosters() external view returns(mapping(uint8 => BoosterStruct)) {
        return(m_boosters);
    }

}