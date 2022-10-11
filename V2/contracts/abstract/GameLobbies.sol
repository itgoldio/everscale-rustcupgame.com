pragma ton - solidity = 0.58 .1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../structs/GameLobbyStruct.sol";

abstract contract GameLobbies {

    mapping(uint8 => GameLobbyStruct) m_lobbies;

    function _addGameLobby(
        uint8 id,
        string name,
        string description,
        uint8 maxPlayers,
        uint8[] rewardSchema,
        uint8 minRegions,
        uint8 maxRegions,
        uint128 price
    ) internal {
        string[] carName;
        address[] playerWalletAddr;
        address[] playerStatisticAddr;
        address[] carNftAddr;
        address[] carNftParametersAddr;
        uint8[] speed;
        uint8[] acceleration;
        uint8[] braking;
        uint8[] control;
        BoosterStruct[] boosters;
        uint256[] results;
        m_lobbies[id] = GameLobbyStruct(
            name,
            description,
            maxPlayers,
            price,
            minRegions,
            maxRegions,
            rewardSchema,
            carName,
            playerWalletAddr,
            playerStatisticAddr,
            carNftAddr,
            carNftParametersAddr,
            speed,
            acceleration,
            braking,
            control,
            boosters,
            results
        );
    }

    function _removeGameLobby(uint8 id) internal {
        delete m_lobbies[id];
    }

    function getGameLobbies() external view returns(mapping(uint8 => GameLobbyStruct)) {
        return(m_lobbies);
    }

}