pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../debot_imports/DeBot.sol";
import "../../debot_imports/Terminal.sol";
import "../../debot_imports/Sdk.sol";
import "../../debot_imports/Menu.sol";

import "../../interfaces/IParameter.sol";
import "../../interfaces/IQueue.sol";

import "../../structs/GameLobbyStruct.sol";
import "../../resolvers/ParameterResolver.sol";
import "../../access/Ownable.sol";

interface Structs {
    struct ParticipationRequest {
        address userWalletAddr;
        address carNftAddr;
        uint8 gameLobbyId;
        uint8 boosterId;
    }
    struct CollectionItem {
        address parameterRootAddr;
        address carNftAddr;
        string carName;
        string carDescription;
        uint8 speed;
        uint8 acceleration;
        uint8 braking;
        uint8 control;
        uint32 totalRaces;
        uint32[] prizePlaces;
    }

    struct CollectionSearchRequest {
        address initiatorAddr;
        bool print;
        uint32 itemAmount;
        CollectionItem[] collection; 
    }
}

abstract contract Utility {
    function tonsToStr(uint128 nanotons) internal pure returns (string) {
        (uint64 dec, uint64 float) = _tokens(nanotons);
        string floatStr = format("{}", float);
        while (floatStr.byteLength() < 9) {
            floatStr = "0" + floatStr;
        }
        return format("{}.{}", dec, floatStr);
    }

    function _tokens(uint128 nanotokens) internal pure returns (uint64, uint64) {
        uint64 decimal = uint64(nanotokens / 1e9);
        uint64 float = uint64(nanotokens - (decimal * 1e9));
        return (decimal, float);
    }
}

abstract contract Strings is Utility {
    string constant technicalPauseStr = "🔴 Technical pause!";
    string constant lobbiesMenuStr = "🔘 Lobbies Menu";
    string constant boostersMenuStr = "🔘 Boosters Menu";
    string constant carsMenuStr = "🔘 Cars Menu";
    string constant transactionSuccessStr = "✅ Transaction success!";
    string constant carIsBusyStr = "🔴 The car is already in the lobby!";
    string constant backStr = "Back";

    function getLobbyStr(GameLobbyStruct lobby) internal view returns(string str){
        str = format("🏁 Lobby «{}»\n📃 Description: {}\n\n🎲 Max players: {}\n📏 Track length: {}-{} units\n\n🆓 Lobby status: \n{}\n\n🏅 Rewards:\n{}\n\n💰 Price: {} EVER's",
            lobby.name,
            lobby.description,
            lobby.maxPlayers,
            lobby.minRegions,
            lobby.maxRegions,
            getLobbyFullness(lobby),
            getLobbyRewardSchema(lobby),
            tonsToStr(lobby.price)
        );
    }

    function getLobbyFullness(GameLobbyStruct lobby) internal view returns(string str) {
        for(uint8 i = 0; i < lobby.maxPlayers; i++) {
            if(i < lobby.carName.length) {
                str = str + "🔴" + format(" {}", lobby.carName[i]) + "\n";
            }
            else{
                str = str + "🟢" + " Free" + "\n";
            }
        }
    }

    function getLobbyRewardSchema(GameLobbyStruct lobby) internal view returns(string str) {
        for(uint8 i = 0; i < lobby.rewardSchema.length; i++) {
            if(i == 0) {
                str = str + format("👷 Developers reward: {}%", lobby.rewardSchema[i]);
            }
            else if(i == 1) {
                str = str + format("\n🥇 {} place: {}%", i, lobby.rewardSchema[i]);
            }
            else if(i == 2) {
                str = str + format("\n🥈 {} place: {}%", i, lobby.rewardSchema[i]);
            }
            else if(i == 3) {
                str = str + format("\n🥉 {} place: {}%", i, lobby.rewardSchema[i]);
            }
            else{
                str = str + format("\n{} place: {}%", i, lobby.rewardSchema[i]);
            }
        }
    }

    function getBoosterStr(BoosterStruct booster) internal view returns(string str){
        str = format("🚀 Booster «{}»\n\n⏩ Speed: {}\n🔥 Acceleration: {}\n🛑 Braking: {}\n⚙ Control: {}",
            booster.name,
            getFormatedBoosterValue(booster.speedBooster),
            getFormatedBoosterValue(booster.accelerationBooster),
            getFormatedBoosterValue(booster.brakingBooster),
            getFormatedBoosterValue(booster.controlBooster)
        );
    }

    function getFormatedBoosterValue(int8 value) internal view returns(string str) {
        if(value < 0) {
            str = format("{}%", value);
        }
        else if(value == 0) {
            str = format("{}%", value);
        }
        else {
            str = "+" + format("{}%", value);
        }
    }
}

interface IMultisig {
    function submitTransaction(
        address  dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload
    )
    external returns (uint64 transId);
}

interface IQueueAccess {
    function status() external returns(bool);
}

interface IQueueGameLobbies {
    function getGameLobbies() external returns(mapping(uint8 => GameLobbyStruct));
}

interface IQueueBoosters {
    function getBoosters() external returns(mapping(uint8 => BoosterStruct));
}

interface IQueueParticipationRequest {
    function checkCarInLobby(address car, uint8 gameLobbyId) external returns(bool acceptStatus);
    function acceptParticipateRequest(address carNftAddr, uint8 boosterId, uint8 gameLobbyId) external;
}

interface IMainDebot {
    function mainMenu() external;
}

interface ICollectionHelperDebot {
    function searchCollection(
        uint8 initiatorId, 
        address nftRootAddr,
        address ownerAddr, 
        bool print,
        TvmCell _parameterCode,
        address _mainDebotAddr,
        address _participationHelperDebotAddr,
        address _parameterRootAddr,
        address _nftHelperAddr
    ) external;
}

contract ParticipationHelperDebot is DeBot, Ownable, Structs, Strings {

    address queueAddr;
    address mainDebotAddr;
    address collectionHelperDebotAddr;
    address nftRootAddr;

    ParticipationRequest participationRequest;

    mapping(uint8 => GameLobbyStruct) m_lobbies;
    mapping(uint8 => BoosterStruct) m_boosters;
    CollectionItem[] collection;

    constructor(uint256 ownerPubkey) Ownable(ownerPubkey) public {
        tvm.accept();
    }

    function start() public override {}

    function getQueueStatus(
        address userWalletAddr,
        address _mainDebotAddr,
        address _queueAddr,
        address _nftRootAddr,
        address _collectionHelperDebotAddr
    ) public {
        mainDebotAddr = _mainDebotAddr;
        queueAddr = _queueAddr;
        nftRootAddr = _nftRootAddr;
        collectionHelperDebotAddr = _collectionHelperDebotAddr;

        participationRequest.userWalletAddr = userWalletAddr;
        optional(uint256) none;
        IQueueAccess(queueAddr).status{
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: onGetQueueStatus,
            onErrorId: onError
        }().extMsg;
    }

    function onGetQueueStatus(bool paused) public {
        if(paused) {
            Terminal.print(0, technicalPauseStr);
            backToMainMenu();
        }
        else {
            getGameLobbiesList();
        }
    }

    function getGameLobbiesList() public {
        optional(uint256) none;
        IQueueGameLobbies(queueAddr).getGameLobbies{
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: onGetGameLobbies,
            onErrorId: onError
        }().extMsg;
    }

    function onGetGameLobbies(mapping(uint8 => GameLobbyStruct) lobbies) public {
        MenuItem[] _lobbiesMenu;
        m_lobbies = lobbies;
        for((uint8 key, GameLobbyStruct lobby) : lobbies) {
            Terminal.print(0, getLobbyStr(lobby));
            _lobbiesMenu.push(MenuItem(lobby.name,"",tvm.functionId(selectGameLobby)));
        }
        _lobbiesMenu.push(MenuItem(backStr,"",tvm.functionId(backToMainMenu)));
        Menu.select(lobbiesMenuStr, "", _lobbiesMenu);
    }

    function selectGameLobby(uint32 index) public {
        participationRequest.gameLobbyId = uint8(index);
        Terminal.print(0, format("✅ «{}» selected!", m_lobbies[uint8(index)].name));
        getBoosters();
    }

    function getBoosters() public {
        optional(uint256) none;
        IQueueBoosters(queueAddr).getBoosters{
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: onGetBoosters,
            onErrorId: onError
        }().extMsg;
    }

    function onGetBoosters(mapping(uint8 => BoosterStruct) boosters) public {
        MenuItem[] _boostersMenu;
        m_boosters = boosters;
        for((uint8 key, BoosterStruct booster) : boosters) {
            Terminal.print(0, getBoosterStr(booster));
            _boostersMenu.push(MenuItem(booster.name,"",tvm.functionId(selectBooster)));
        }
        _boostersMenu.push(MenuItem(backStr,"",tvm.functionId(backToMainMenu)));
        Menu.select(boostersMenuStr, "", _boostersMenu);
    }

    function selectBooster(uint32 index) public {
        participationRequest.boosterId = uint8(index);
        Terminal.print(0, format("✅ «{}» selected!", m_boosters[uint8(index)].name));
        getCollection();
    }

    function getCollection() public {
        TvmCell empty;
        ICollectionHelperDebot(collectionHelperDebotAddr).searchCollection(
            1, 
            nftRootAddr, 
            participationRequest.userWalletAddr, 
            false,
            empty,
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    function onGetCollection(CollectionSearchRequest collectionSearchRequest) public {
        MenuItem[] _carsMenu;
        collection = collectionSearchRequest.collection;
        for(CollectionItem item : collection) {
            if(item.carNftAddr != address(0)) {
                _carsMenu.push(MenuItem(item.carName,"",tvm.functionId(selectCar)));
            }
        }
        _carsMenu.push(MenuItem(backStr,"",tvm.functionId(backToMainMenu)));
        Menu.select(carsMenuStr, "", _carsMenu);
    }

    function selectCar(uint32 index) public {
        participationRequest.carNftAddr = collection[uint8(index)].carNftAddr;
        Terminal.print(tvm.functionId(checkCarInLobby), format("✅ «{}» selected!", collection[uint8(index)].carName));
    }

    function checkCarInLobby() public {
        optional(uint256) none;
        IQueueParticipationRequest(queueAddr).checkCarInLobby{
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: submitTransaction,
            onErrorId: onError
        }(participationRequest.carNftAddr, participationRequest.gameLobbyId).extMsg;
    }

    function submitTransaction(bool value) public {
        if(value) {
            Terminal.print(0, carIsBusyStr);
            backToMainMenu();
        }
        else {
            TvmCell payload = tvm.encodeBody(IQueueParticipationRequest.acceptParticipateRequest, participationRequest.carNftAddr, participationRequest.boosterId, participationRequest.gameLobbyId);
            optional(uint256) pubkey = 0;
            IMultisig(participationRequest.userWalletAddr).submitTransaction{
                sign: true, 
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: onSuccessTransaction,
                onErrorId: onError
            }(queueAddr, m_lobbies[participationRequest.gameLobbyId].price, true, false, payload).extMsg;
        }
    }

    function onSuccessTransaction(uint64 transId) public {
        Terminal.print(0, transactionSuccessStr);
        backToMainMenu();
    }

    function backToMainMenu() public {
        IMainDebot(mainDebotAddr).mainMenu();
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("SdkError: {}, exitCode: {}", sdkError, exitCode));
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "🏁 Rust Cup Game";
        version = "2.0.0";
        publisher = "https://github.com/itgoldio";
        caption = "🏁 The First True NFT game on the Everscale!";
        author = "https://github.com/itgoldio";
        support = address.makeAddrStd(0, 0x5fb73ece6726d59b877c8194933383978312507d06dda5bcf948be9d727ede4b);
        hello = "🏁 Welcome to Rust Cup Game!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
         return [Sdk.ID, Terminal.ID, Menu.ID];
    }

}
