pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../access/Ownable.sol";
import "../../access/Manageable.sol";
import "../../access/Pausable.sol";

import "../../abstract/Boosters.sol";
import "../../abstract/GameLobbies.sol";
import "../../abstract/WorkTax.sol";

import "../../errors/QueueErrors.sol";

import "../../interfaces/IQueue.sol";
import "../../interfaces/ICarNftData.sol";
import "../../interfaces/IParameter.sol";
import "../../interfaces/ITrackRoot.sol";

import "../../resolvers/PlayerResolver.sol";
import "../../resolvers/ParameterResolver.sol";
import "../../resolvers/TrackResolver.sol";

library QueueConstants {
    uint128 constant getter_msg_value = 0.2 ton;
    uint128 constant work_tax_value = 0.4 ton;
}

interface QueueEvents {
    event NewParticipateRequest(
        address playerWalletAddr, 
        address playerStatisticAddr, 
        address carNftAddr,
        uint8 boosterId,
        uint8 gameLobbyId
    );
    event LobbyReady(GameLobbyStruct lobby);
}

contract Queue is
IQueue,
Ownable,
Manageable,
Boosters,
GameLobbies,
PlayerResolver,
ParameterResolver,
TrackResolver,
WorkTax,
Pausable,
QueueEvents
{

    TvmCell playerCode;
    TvmCell parameterCode;
    address trackRootAddr;
    address playerRootAddr;
    address parameterRootAddr;

    uint256 requestId;
    mapping(uint256 => PlayerStruct) m_queue;
    mapping(address => uint256) m_carNftAddrToRequestId;
    mapping(address => uint256) m_carParameterAddrToRequestId;

    constructor(
        uint256 ownerPubkey,
        uint256 managerPubkey,
        TvmCell _playerCode,
        TvmCell _parameterCode,
        address _trackRootAddr,
        address _playerRootAddr,
        address _parameterRootAddr
    )
    Ownable(ownerPubkey)
    Manageable(managerPubkey)
    WorkTax(QueueConstants.work_tax_value)
    Pausable()
    public {
        tvm.accept();
        playerCode = _playerCode;
        parameterCode = _parameterCode;
        trackRootAddr = _trackRootAddr;
        playerRootAddr = _playerRootAddr;
        parameterRootAddr = _parameterRootAddr;
    }

    function acceptParticipateRequest(
        address carNftAddr,
        uint8 boosterId,
        uint8 gameLobbyId
    ) external override whenNotPaused {
        require(msg.value == m_lobbies[gameLobbyId].price, QueueErrors.low_msg_value);
        tvm.accept();
        if(!checkCarInLobby(carNftAddr, gameLobbyId)) {
            m_queue[requestId] = PlayerStruct(
                "",
                msg.sender,
                resolvePlayer(playerCode, msg.sender, playerRootAddr),
                carNftAddr,
                address(0),
                0,
                0,
                0,
                0,
                gameLobbyId,
                boosterId
            );
            m_carNftAddrToRequestId[carNftAddr] = requestId;
            requestId++;
            getCarNftOwner(carNftAddr);
        }
        else {
            msg.sender.transfer({value: msg.value - _getCalculateTaxValue(1), flag: 0});
        }
    }

    function checkCarInLobby(address car, uint8 gameLobbyId) public view returns(bool acceptStatus) {
        if(m_lobbies[gameLobbyId].carNftAddr.length != 0) {
            for(address value : m_lobbies[gameLobbyId].carNftAddr) {
                if(car == value) {
                    acceptStatus = true;
                }
            }
        }
    }

    function getCarNftOwner(address carNftAddr) internal pure {
        ICarNftData(carNftAddr).getInfo {
            value: QueueConstants.getter_msg_value,
            flag: 0,
            callback: Queue.onGetCarNftOwner
        }();
    }

    function onGetCarNftOwner(
        uint256 id, 
        address owner, 
        address manager, 
        address collection
    ) external {
        require(m_carNftAddrToRequestId.exists(msg.sender), QueueErrors.not_verified_car_msg);
        tvm.accept();
        id; 
        manager; 
        collection;
        uint256 currentRequestId = m_carNftAddrToRequestId[msg.sender];
        delete m_carNftAddrToRequestId[msg.sender];
        if (m_queue[currentRequestId].playerWalletAddr == owner) {
            getCarParameters(msg.sender, currentRequestId);
        }
    }

    function getCarParameters(address carNftAddr, uint256 currentRequestId) internal {
        address parameterAddr = resolveParameter(parameterCode, carNftAddr, parameterRootAddr);
        m_carParameterAddrToRequestId[parameterAddr] = currentRequestId;
        IParameter(parameterAddr).getInfo {
            value: QueueConstants.getter_msg_value,
            flag: 0,
            callback: Queue.onGetCarParameters
        }();
    }

    function onGetCarParameters(
        address _parameterRootAddr,
        address _carNftAddr,
        string carName,
        string _carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) external {
        require(m_carParameterAddrToRequestId.exists(msg.sender), QueueErrors.not_verified_parameter_msg);
        tvm.accept();
        _parameterRootAddr;
        _carNftAddr;
        _carDescription;
        _totalRaces;
        _prizePlaces;
        uint256 currentRequestId = m_carParameterAddrToRequestId[msg.sender];
        delete m_carParameterAddrToRequestId[msg.sender];
        m_queue[currentRequestId].carName = carName;
        m_queue[currentRequestId].carNftParametersAddr = msg.sender;
        (uint8 speedBoosted, uint8 accelerationBoosted, uint8 brakingBoosted, uint8 controlBoosted) = _applyBooster(
            m_queue[currentRequestId].boosterId,
            speed,
            acceleration,
            braking,
            control
        );
        m_queue[currentRequestId].speed = speedBoosted;
        m_queue[currentRequestId].acceleration = accelerationBoosted;
        m_queue[currentRequestId].braking = brakingBoosted;
        m_queue[currentRequestId].control = controlBoosted;

        emit QueueEvents.NewParticipateRequest(
            m_queue[currentRequestId].playerWalletAddr,
            m_queue[currentRequestId].playerStatisticAddr,
            m_queue[currentRequestId].carNftAddr,
            m_queue[currentRequestId].boosterId,
            m_queue[currentRequestId].gameLobbyId
        );

        acceptToLobby(currentRequestId);
    }

    function _applyBooster(
        uint8 boosterId,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control
    ) internal view returns(
        uint8 boostedSpeed,
        uint8 boostedAcceleration,
        uint8 boostedBraking,
        uint8 boostedControl
    ) {
        boostedSpeed = math.min(uint8(100), uint8(int8(speed) + (int16(speed) * int16(m_boosters[boosterId].speedBooster)) / 100));
        boostedAcceleration = math.min(uint8(100), uint8(int8(acceleration) + (int16(acceleration) * int16(m_boosters[boosterId].accelerationBooster)) / 100));
        boostedBraking = math.min(uint8(100), uint8(int8(braking) + (int16(braking) * int16(m_boosters[boosterId].brakingBooster)) / 100));
        boostedControl = math.min(uint8(100), uint8(int8(control) + (int16(control) * int16(m_boosters[boosterId].controlBooster)) / 100));
    }

    function acceptToLobby(uint256 _requestId) internal {
        m_lobbies[m_queue[_requestId].gameLobbyId].carName.push(m_queue[_requestId].carName);
        m_lobbies[m_queue[_requestId].gameLobbyId].playerWalletAddr.push(m_queue[_requestId].playerWalletAddr);
        m_lobbies[m_queue[_requestId].gameLobbyId].playerStatisticAddr.push(m_queue[_requestId].playerStatisticAddr);
        m_lobbies[m_queue[_requestId].gameLobbyId].carNftAddr.push(m_queue[_requestId].carNftAddr);
        m_lobbies[m_queue[_requestId].gameLobbyId].carNftParametersAddr.push(m_queue[_requestId].carNftParametersAddr);
        m_lobbies[m_queue[_requestId].gameLobbyId].speed.push(m_queue[_requestId].speed);
        m_lobbies[m_queue[_requestId].gameLobbyId].acceleration.push(m_queue[_requestId].acceleration);
        m_lobbies[m_queue[_requestId].gameLobbyId].braking.push(m_queue[_requestId].braking);
        m_lobbies[m_queue[_requestId].gameLobbyId].control.push(m_queue[_requestId].control);
        m_lobbies[m_queue[_requestId].gameLobbyId].boosters.push(m_boosters[m_queue[_requestId].boosterId]);
        m_lobbies[m_queue[_requestId].gameLobbyId].results.push(0);

        if (m_lobbies[m_queue[_requestId].gameLobbyId].carNftAddr.length == m_lobbies[m_queue[_requestId].gameLobbyId].maxPlayers) {
            emit QueueEvents.LobbyReady(m_lobbies[m_queue[_requestId].gameLobbyId]);
            ITrackRoot(trackRootAddr).mintTrack {
                    value: 
                        (m_lobbies[m_queue[_requestId].gameLobbyId].price * m_lobbies[m_queue[_requestId].gameLobbyId].maxPlayers)
                        -
                        (_getCalculateTaxValue(m_lobbies[m_queue[_requestId].gameLobbyId].maxPlayers))
                    ,
                    flag: 0
                }
            (m_lobbies[m_queue[_requestId].gameLobbyId]);

            delete m_lobbies[m_queue[_requestId].gameLobbyId].carName;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].playerWalletAddr;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].playerStatisticAddr;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].carNftAddr;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].carNftParametersAddr;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].speed;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].acceleration;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].braking;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].control;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].boosters;
            delete m_lobbies[m_queue[_requestId].gameLobbyId].results;
        }

        delete m_queue[_requestId];
    }

    function addGameLobby(
        uint8 id,
        string name,
        string description,
        uint8 maxPlayers,
        uint8[] rewardSchema,
        uint8 minRegions,
        uint8 maxRegions,
        uint128 price
    ) external onlyManager whenPaused {
        tvm.accept();
        _addGameLobby(
            id,
            name,
            description,
            maxPlayers,
            rewardSchema,
            minRegions,
            maxRegions,
            price
        );
    }

    function removeGameLobby(uint8 id) external onlyManager whenPaused {
        tvm.accept();
        _removeGameLobby(id);
    }

    function addBooster(
        uint8 id,
        string name,
        int8 speedBooster,
        int8 accelerationBooster,
        int8 brakingBooster,
        int8 controlBooster
    ) external onlyManager whenPaused {
        tvm.accept();
        _addBooster(
            id,
            name,
            speedBooster,
            accelerationBooster,
            brakingBooster,
            controlBooster
        );
    }

    function removeBooster(uint8 id) external onlyManager whenPaused {
        tvm.accept();
        _removeBooster(id);
    }

    function changeManager(uint256 newManagerPubkey) external onlyOwner {
        tvm.accept();
        _changeManager(newManagerPubkey);
    }

    function pause() external onlyManager whenNotPaused {
        tvm.accept();
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        tvm.accept();
        _unpause();
    }

    function clearQueue() external onlyManager whenPaused {
        tvm.accept();
        delete m_queue;
        delete m_carNftAddrToRequestId;
        delete m_carParameterAddrToRequestId;
    }

    function setPlayerCode(TvmCell newPlayerCode) external onlyManager whenPaused {
        tvm.accept();
        playerCode = newPlayerCode;
    }

    function setParameterCode(TvmCell newParameterCode) external onlyManager whenPaused {
        tvm.accept();
        parameterCode = newParameterCode;
    }

    function setTrackRootAddr(address newTrackRootAddr) external onlyManager whenPaused {
        tvm.accept();
        trackRootAddr = newTrackRootAddr;
    }

    function setPlayerRootAddr(address newPlayerRootAddr) external onlyManager whenPaused {
        tvm.accept();
        playerRootAddr = newPlayerRootAddr;
    }

    function setParameterRootAddr(address newParameterRootAddr) external onlyManager whenPaused {
        tvm.accept();
        parameterRootAddr = newParameterRootAddr;
    }

    function getInfo() external override view returns(
        TvmCell _playerCode,
        TvmCell _parameterCode,
        address _trackRootAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        uint256 _requestId,
        mapping(uint256 => PlayerStruct) _m_queue
    ) {
        return(
            playerCode,
            parameterCode,
            trackRootAddr,
            playerRootAddr,
            parameterRootAddr,
            requestId,
            m_queue
        );
    }

    function withdraw(address dest, uint128 value, bool bounce) external pure onlyOwner whenPaused {
        tvm.accept();
        dest.transfer(value, bounce, 0);
    }

    function destruct(address addr) external onlyOwner whenPaused {
        tvm.accept();
        selfdestruct(addr);
    }

}