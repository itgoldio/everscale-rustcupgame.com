pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../debot_imports/DeBot.sol";
import "../../debot_imports/Terminal.sol";
import "../../debot_imports/Sdk.sol";
import "../../debot_imports/Menu.sol";
import "../../debot_imports/UserInfo.sol";
import "../../debot_imports/ConfirmInput.sol";

import "../../interfaces/IPlayer.sol";

import "../../resolvers/PlayerResolver.sol";

import "../../access/Ownable.sol";

interface Structs {
    struct User {
        address walletAddr;
        address playerAddr;
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

interface IParticipationHelperDebot {
    function getQueueStatus(
        address userWalletAddr,
        address _mainDebotAddr,
        address _queueAddr,
        address _nftRootAddr,
        address _collectionHelperDebotAddr
    ) external;
}

interface IPlayerRoot {
    function mintPlayerByWallet() external;
    function getInfo() external view returns(
        TvmCell _playerCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue 
    );
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

abstract contract Strings {
    function getCarItemStr(
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) internal returns(string str) {
        str = format("🏎 Car: {}\n📃 Description: {}\n\n⏩ Speed: {}\n🔥 Acceleration: {}\n🛑 Braking: {}\n⚙ Control: {}\n\n🥇 : {}\n🥈 : {}\n🥉 : {}\n🏆 Total races: {}",
            _carName,
            _carDescription,
            _speed,
            _acceleration,
            _braking,
            _control,
            _prizePlaces[0],
            _prizePlaces[1],
            _prizePlaces[2],
            _totalRaces
        );
    }

    function getStatsStr(
        uint32 totalRaces,
        uint32[] prizePlaces
    ) internal returns(string str) {
        str = format("👤 My Stats:\n\n🏁 Total Races: {}\n\n🥇 : {}\n🥈 : {}\n🥉 : {}",
            totalRaces,
            prizePlaces[0],
            prizePlaces[1],
            prizePlaces[2]
        );
    }

}

contract MainDebot is DeBot, Structs, Strings, Ownable, PlayerResolver {

    bool status;

    User user;
    TvmCell playerCode;
    TvmCell parameterCode;
    address playerRootAddr;
    address parameterRootAddr;
    address nftRootAddr;
    address nftHelperAddr;
    address queueAddr;
    address collectionHelperDebotAddr;
    address participationHelperDebotAddr;
    bytes _m_icon;

    constructor(
        uint256 ownerPubkey,
        TvmCell _playerCode,
        TvmCell _parameterCode,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _nftRootAddr,
        address _nftHelperAddr,
        address _queueAddr,
        address _collectionHelperDebotAddr,
        address _participationHelperDebotAddr
    ) Ownable(ownerPubkey) public {
        tvm.accept();
        playerCode = _playerCode;
        parameterCode = _parameterCode;
        playerRootAddr = _playerRootAddr;
        parameterRootAddr = _parameterRootAddr;
        nftRootAddr = _nftRootAddr;
        nftHelperAddr = _nftHelperAddr;
        queueAddr = _queueAddr;
        collectionHelperDebotAddr = _collectionHelperDebotAddr;
        participationHelperDebotAddr = _participationHelperDebotAddr;
    }

    function start() public override {
        if(status) {
            Terminal.print(0, "❗ This debot has been disabled!");
        }
        else{
            UserInfo.getAccount(tvm.functionId(setUserWallet));
        }
    }

    function setUserWallet(address value) public {
        user.walletAddr = value;
        user.playerAddr = resolvePlayer(playerCode, user.walletAddr, playerRootAddr);
        Sdk.getAccountType(tvm.functionId(onGetPlayerAddrType), user.playerAddr);
    }

    function onGetPlayerAddrType(int8 acc_type) public {
        if(acc_type == 1) {
            ICollectionHelperDebot(collectionHelperDebotAddr).searchCollection(
                0, 
                nftRootAddr, 
                user.walletAddr, 
                false,
                parameterCode,
                address(this),
                participationHelperDebotAddr,
                parameterRootAddr,
                nftHelperAddr
            );
        }
        else{
            Terminal.print(0, "❗ You need to create a player account!");
            ConfirmInput.get(tvm.functionId(onGetConfirmCreatePlayer), "Create a player account?");
        }
    }

    function onGetConfirmCreatePlayer(bool value) public {
        if(value) {
            optional(uint256) none;
            IPlayerRoot(playerRootAddr).getInfo{
                sign: false,
                pubkey: none,
                time: uint64(now),
                expire: 0,
                callbackId: onGetPlayerRootInfo,
                onErrorId: onError
            }().extMsg;
        }
        else {
            UserInfo.getAccount(tvm.functionId(setUserWallet));
        }
    }

    function onGetPlayerRootInfo(
        TvmCell _playerCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue
    ) public {
        _playerCode;
        _trackCode;
        _trackRootAddr;
        deployPlayerTransaction(_mintProcessingValue + _mintValue);
    }

    function deployPlayerTransaction(uint128 msgValue) public {
        TvmCell payload = tvm.encodeBody(IPlayerRoot.mintPlayerByWallet);
        optional(uint256) pubkey = 0;
        IMultisig(user.walletAddr).submitTransaction{
            sign: true, 
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: onSuccessPlayerDeploy,
            onErrorId: onError
        }(playerRootAddr, msgValue, true, false, payload).extMsg;
    }

    function onSuccessPlayerDeploy(uint64 transId) public {
        Terminal.print(0, "✅ Transaction success!");
        start();
    }

    function noop() public  {
        Terminal.input(tvm.functionId(noop), "", false);
    }

    function mainMenu() public {
        MenuItem[] _mainMenu = [
            MenuItem("Game Lobbies","",tvm.functionId(getLobbiesList)),
            MenuItem("Collection","",tvm.functionId(getCollection)),
            MenuItem("My Stats","",tvm.functionId(getPlayerInfo))
        ];
        Menu.select("🔘 Main Menu", "", _mainMenu);
    }

    function getPlayerInfo() public {
        optional(uint256) none;
        IPlayer(user.playerAddr).getInfo{
            sign: false,
             pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: onGetPlayerInfo,
            onErrorId: onError
        }().extMsg;
    }

    function onGetPlayerInfo(
        address _playerRootAddr,
        address _playerWalletAddr,
        uint256 _totalPoints,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) public {
        Terminal.print(0, getStatsStr(_totalRaces, _prizePlaces));
        mainMenu();
    }

    function getLobbiesList() public {
        IParticipationHelperDebot(participationHelperDebotAddr).getQueueStatus(
            user.walletAddr,
            address(this),
            queueAddr,
            nftRootAddr,
            collectionHelperDebotAddr
        );
    }

    function getCollection() public {
        ICollectionHelperDebot(collectionHelperDebotAddr).searchCollection(
            0, 
            nftRootAddr, 
            user.walletAddr, 
            true,
            parameterCode,
            address(this),
            participationHelperDebotAddr,
            parameterRootAddr,
            nftHelperAddr
        );
    }

    function onGetCollection(CollectionSearchRequest collectionSearchRequest) public {
        if(collectionSearchRequest.print) {
            for(CollectionItem item : collectionSearchRequest.collection) {
                if(item.carNftAddr != address(0)) {
                    Terminal.print(0, getCarItemStr(
                        item.carName,
                        item.carDescription,
                        item.speed,
                        item.acceleration,
                        item.braking,
                        item.control,
                        item.totalRaces,
                        item.prizePlaces
                    ));
                }
            }
        }
        mainMenu();
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
        icon = _m_icon;
    }

    function setIcon(bytes icon) public onlyOwner {
        tvm.accept();
        _m_icon = icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
         return [Sdk.ID, Terminal.ID, Menu.ID, UserInfo.ID, ConfirmInput.ID];
    }

    function setPause(bool pause) external onlyOwner {
        tvm.accept();
        status = pause;
    }

    function setPlayerCode(TvmCell newPlayerCode) external onlyOwner {
        tvm.accept();
        playerCode = newPlayerCode;
    }

    function setParameterCode(TvmCell newParameterCode) external onlyOwner {
        tvm.accept();
        parameterCode = newParameterCode;
    }

    function setPlayerRootAddr(address newPlayerRootAddr) external onlyOwner {
        tvm.accept();
        playerRootAddr = newPlayerRootAddr;
    }

    function setParameterRootAddr(address newParameterRootAddr) external onlyOwner {
        tvm.accept();
        parameterRootAddr = newParameterRootAddr;
    }

    function setNftRootAddr(address newNftRootAddr) external onlyOwner {
        tvm.accept();
        nftRootAddr = newNftRootAddr;
    }

    function setQueueAddr(address newQueueAddr) external onlyOwner {
        tvm.accept();
        queueAddr = newQueueAddr;
    }

    function setCollectionHelperDebotAddr(address newCollectionHelperDebotAddr) external onlyOwner {
        tvm.accept();
        collectionHelperDebotAddr = newCollectionHelperDebotAddr;
    }

    function setParticipationHelperDebotAddr(address newParticipationHelperDebotAddr) external onlyOwner {
        tvm.accept();
        participationHelperDebotAddr = newParticipationHelperDebotAddr;
    }

    function getInfo() external returns(
        uint256 ownerPubkey,
        TvmCell _playerCode,
        TvmCell _parameterCode,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _nftRootAddr,
        address _queueAddr,
        address _collectionHelperDebotAddr,
        address _participationHelperDebotAddr
    ) {
        return(
            owner(),
            playerCode,
            parameterCode,
            playerRootAddr,
            parameterRootAddr,
            nftRootAddr,
            queueAddr,
            collectionHelperDebotAddr,
            participationHelperDebotAddr
        );
    }

}