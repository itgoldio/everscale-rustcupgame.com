pragma ton-solidity = 0.58.1;

import "../structs/PlayerStruct.sol";
import "../structs/GameLobbyStruct.sol";

interface IQueue {
    function acceptParticipateRequest(address carNftAddr, uint8 boosterId, uint8 gameLobbyId) external;
    function getInfo() external view returns(
        TvmCell _playerCode,
        TvmCell _parameterCode,
        address _trackRootAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        uint256 _requestId,
        mapping(uint256 => PlayerStruct) _m_queue
    );
}