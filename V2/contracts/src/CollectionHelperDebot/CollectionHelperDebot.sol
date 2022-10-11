pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../debot_imports/DeBot.sol";
import "../../debot_imports/Terminal.sol";
import "../../debot_imports/Sdk.sol";
import "../../debot_imports/Menu.sol";

import "../../resolvers/ParameterResolver.sol";

import "../../access/Ownable.sol";

interface IParameterGetInfo {
    function getInfo(
        uint32 answerId
    ) external view returns(
        address _parameterRootAddr,
        address _carNftAddr,
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    );
}

interface INftHelper {
    function indexCodeHash(
        uint32 answerId,
        address collection,
        address owner
    ) external view returns (uint256 indexCodeHash);
}

interface IIndex {
    function getInfo(
        uint32 answerId
    ) external returns(
        address collection,
        address owner,
        address nft
    );
}

interface Structs {
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
    struct AccData {
        address id;
        TvmCell data;
    }
}

interface ICollectionReceiver is Structs {
    function onGetCollection(CollectionSearchRequest collectionSearchRequest) external;
}

contract CollectionHelperDebot is DeBot, Structs, Ownable, ParameterResolver {

    address mainDebotAddr;
    address participationHelperDebotAddr;
    CollectionSearchRequest collectionSearchRequest;
    TvmCell parameterCode;
    address parameterRootAddr;
    address nftHelperAddr;

    bool isInit;

    uint8 parametersCheckCounter;
    address[] parametersBuffer;

    constructor(uint256 ownerPubkey) Ownable(ownerPubkey) public {
        tvm.accept();
    }

    function start() public override {
       Terminal.print(0,"Sorry, I can't help you. Bye!");
    }

    function init(
        TvmCell _parameterCode,
        address _mainDebotAddr,
        address _participationHelperDebotAddr,
        address _parameterRootAddr,
        address _nftHelperAddr
    ) public {
        parameterCode = _parameterCode;
        mainDebotAddr = _mainDebotAddr;
        parameterRootAddr = _parameterRootAddr;
        participationHelperDebotAddr = _participationHelperDebotAddr;
        nftHelperAddr = _nftHelperAddr;
    }

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
    ) public {
        if(!isInit) {
            init(
                _parameterCode,
                _mainDebotAddr,
                _participationHelperDebotAddr,
                _parameterRootAddr,
                _nftHelperAddr
            );
            isInit = true;
        }
        delete collectionSearchRequest;
        delete parametersBuffer;
        parametersCheckCounter = 0;
        if(initiatorId == 0) {
            collectionSearchRequest.initiatorAddr = mainDebotAddr;
        }
        else if(initiatorId == 1) {
            collectionSearchRequest.initiatorAddr = participationHelperDebotAddr;
        }
        collectionSearchRequest.print = print;
        optional(uint256) none;
        INftHelper(nftHelperAddr).indexCodeHash{
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: onResolveCodeHashIndex,
            onErrorId: onError
        }(0, nftRootAddr, ownerAddr).extMsg;
    }

    function onResolveCodeHashIndex(uint256 indexCodeHash) public {
        Sdk.getAccountsDataByHash(
            tvm.functionId(onGetIndexesByHash),
            indexCodeHash,
            address.makeAddrStd(0, 0)
        );
    }

    function onGetIndexesByHash(AccData[] accounts) public {
        collectionSearchRequest.itemAmount = uint32(accounts.length);
        if(accounts.length > 0) {
            for(uint16 i = 0; i < accounts.length; i++) {
                IIndex(accounts[i].id).getInfo{
                    sign: false,
                    time: uint64(now),
                    callbackId: onGetIndexesInfo,
                    onErrorId: onError
                }(0).extMsg;
            }
        }
        else {
            Terminal.print(0, "❗ You don't have a collection of cars, buy them on grandbazar.io and come back");
        }
    }

    function onGetIndexesInfo(
        address collection,
        address owner,
        address nft
    ) public {
        collection;
        owner;
        address carParameterAddr = resolveParameter(parameterCode, nft, parameterRootAddr);
        parametersBuffer.push(carParameterAddr);
        Sdk.getAccountType(tvm.functionId(onGetParameterType), carParameterAddr);
    }

    function onGetParameterType(int8 acc_type) public {
        if(acc_type == 1) {
            optional(uint256) none;
            IParameterGetInfo(parametersBuffer[parametersCheckCounter]).getInfo{
                sign: false,
                pubkey: none,
                time: uint64(now),
                expire: 0,
                callbackId: onGetParametersInfo,
                onErrorId: onError
            }(0).extMsg;
        }
        else {
            collectionSearchRequest.collection.push(
                CollectionItem(
                    address(0),
                    address(0),
                    "",
                    "",
                    0,
                    0,
                    0,
                    0,
                    0,
                    [uint32(0),0,0]
                )
            );
            if(collectionSearchRequest.collection.length == collectionSearchRequest.itemAmount) {
                ICollectionReceiver(collectionSearchRequest.initiatorAddr).onGetCollection(collectionSearchRequest);
            }
        }
        parametersCheckCounter++;
    }

    function onGetParametersInfo(
        address _parameterRootAddr,
        address _carNftAddr,
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) public {
        collectionSearchRequest.collection.push(
            CollectionItem(
                _parameterRootAddr,
                _carNftAddr,
                _carName,
                _carDescription,
                _speed,
                _acceleration,
                _braking,
                _control,
                _totalRaces,
                _prizePlaces
            )
        );
        if(collectionSearchRequest.collection.length == collectionSearchRequest.itemAmount) {
            ICollectionReceiver(collectionSearchRequest.initiatorAddr).onGetCollection(collectionSearchRequest);
        }
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