pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/IRandomGenerator.sol";
import "../../interfaces/IFormula.sol";
import "../../interfaces/IPlayerRoot.sol";
import "../../interfaces/IParameterRoot.sol";
import "../../interfaces/ITrack.sol";

import "../../errors/TrackErrors.sol";

library TrackConstants {
    uint128 constant contract_lock_value = 0.1 ton;
    uint128 constant getter_msg_value = 0.3 ton;
    uint128 constant rewards_msg_value = 1 ton;
    uint128 constant calculate_msg_value = 1 ton;
    uint128 constant update_msg_value_per_player = 0.1 ton;
}

interface TrackEvents {
    event OnGetRandomRegionsCount(uint8 random);
    event OnGetRandomRegionIndexes(uint8[] randoms);
    event OnGetRandomRegionsDifficulties(uint8[] randoms);
    event RegionComplite(
        uint256[] beforePoints,
        uint256[] afterPoints,
        bool[] controlLosses,
        uint8 regionDifficulty,
        uint8 regionNumber,
        RegionStruct region
    );
    event TrackComplite(GameLobbyStruct lobby, mapping(address => uint128) carRewards);
    event BurnByRoot(address trackRootAddr);
}

contract Track is ITrack, TrackEvents {

    address static trackRootAddr;
    uint256 static trackId;

    address formulaAddr;
    address randomGeneratorAddr;
    address playerRootAddr;
    address parameterRootAddr;
    address feeAccumulationAddr;

    GameLobbyStruct lobby;
    RegionStruct[] regions;

    uint8[] regionIndexes;
    uint8[] regionDifficulties;

    constructor(
        address _formulaAddr,
        address _randomGeneratorAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        RegionStruct[] _regions,
        GameLobbyStruct _lobby
    ) public onlyRoot {
        tvm.accept();
        formulaAddr = _formulaAddr;
        randomGeneratorAddr = _randomGeneratorAddr;
        playerRootAddr = _playerRootAddr;
        parameterRootAddr = _parameterRootAddr;
        feeAccumulationAddr = _feeAccumulationAddr;
        regions = _regions;
        lobby = _lobby;
        getRandomRegionsCount();
    }

    function getRandomRegionsCount() internal view {
        IRandomGenerator(randomGeneratorAddr).getRandomArray {
            value: TrackConstants.getter_msg_value,
            flag: 0,
            callback: Track.onGetRandomRegionsCount
        }(1, (lobby.maxRegions - lobby.minRegions) + 1, 0);
    }

    function onGetRandomRegionsCount(uint8[] randoms) external view onlyRandomGenerator {
        tvm.accept();
        IRandomGenerator(randomGeneratorAddr).getRandomArray {
            value: TrackConstants.getter_msg_value,
            flag: 0,
            callback: Track.onGetRandomRegionsIndexes
        }((lobby.minRegions - 1) + randoms[0], uint8(regions.length) - 1, 1);
    }

    function onGetRandomRegionsIndexes(uint8[] randoms) external onlyRandomGenerator {
        tvm.accept();
        regionIndexes.push(0);
        for(uint8 i = 0; i < randoms.length; i++) {
            regionIndexes.push(randoms[i]);
        }
        IRandomGenerator(randomGeneratorAddr).getRandomArray {
            value: TrackConstants.getter_msg_value,
            flag: 0,
            callback: Track.onGetRandomRegionsDifficulties
        }(uint8(regionIndexes.length), 100, 1);
    }

    function onGetRandomRegionsDifficulties(uint8[] randoms) external onlyRandomGenerator {
        tvm.accept();
        regionDifficulties = randoms;
        emit TrackEvents.OnGetRandomRegionsCount(uint8(regionIndexes.length));
        emit TrackEvents.OnGetRandomRegionIndexes(regionIndexes);
        emit TrackEvents.OnGetRandomRegionsDifficulties(regionDifficulties);
        _nextRegion(0, 0);
    }

    function nextRegion(
        uint256[] totalPoints,
        uint8 lastVel,
        bool[] controlLosses,
        uint8 regionNumber
    ) external onlyFormula {
        tvm.accept();

        uint256[] beforePoints = lobby.results;

        for (uint8 i = 0; i < lobby.maxPlayers; i++) {
            lobby.results[i] += totalPoints[i];
        }

        emit TrackEvents.RegionComplite(
            beforePoints,
            lobby.results,
            controlLosses,
            regionDifficulties[regionNumber],
            regionNumber,
            regions[regionIndexes[regionNumber]]
        );

        regionNumber++;
        if (regionNumber < regionIndexes.length) {
            _nextRegion(regionNumber, lastVel);
        } else {
            _acceptPlaces();
            Track(address(this)).paymentRewards {
                value: TrackConstants.rewards_msg_value,
                flag: 1
            }();
        }
    }

    function _nextRegion(uint8 regionNumber, uint8 lastVel) internal view {
        bool isLastRegion;
        if(regionNumber == regionIndexes.length - 1) {
            isLastRegion = true;
        }

        IFormula(formulaAddr).calculate {
            value: TrackConstants.calculate_msg_value,
            flag: 0,
            callback: Track.nextRegion
        }(
            regions[regionIndexes[regionNumber]],
            lobby.maxPlayers,
            lobby.speed,
            lobby.acceleration,
            lobby.braking,
            lobby.control,
            lastVel,
            regionDifficulties[regionNumber],
            regionNumber,
            isLastRegion
        );
    }

    function _acceptPlaces() internal view {
        uint32[] places = _getPlaces();
        uint256[] results = new uint256[](lobby.maxPlayers);
        IPlayerRoot(playerRootAddr).updatePlayers {
            value: TrackConstants.update_msg_value_per_player * lobby.maxPlayers,
            flag: 1
        }(
            trackId,
            lobby.playerStatisticAddr,
            results,
            places
        );

        IParameterRoot(parameterRootAddr).updateParameters {
            value: TrackConstants.update_msg_value_per_player * lobby.maxPlayers,
            flag: 1
        }(
            trackId,
            lobby.carNftParametersAddr,
            places
        );
    }

    function _getPlaces() internal view returns(uint32[] places) {
        for (uint8 i = 0; i < lobby.maxPlayers; i++) {
            uint32 place;
            for (uint8 k = 0; k < lobby.maxPlayers; k++) {
                if (
                    (lobby.results[i] < lobby.results[k]) ||
                    (lobby.results[i] == lobby.results[k] && i > k)
                ) {
                    place++;
                }
            }
            places.push(place);
        }
    }

    function paymentRewards() external view onlySelf {
        tvm.accept();
        tvm.rawReserve(TrackConstants.contract_lock_value, 0);
        uint32[] places = _getPlaces();

        mapping(address=>uint128) carAddrToReward;

        for (uint8 i = 1; i < lobby.rewardSchema.length; i++) {
            lobby.playerWalletAddr[places[i - 1]].transfer({
                value: (lobby.price*lobby.maxPlayers / 100) * lobby.rewardSchema[i],
                flag: 1
            });
            carAddrToReward[lobby.carNftAddr[places[i - 1]]] = (lobby.price*lobby.maxPlayers  / 100) * lobby.rewardSchema[i];
        }

        feeAccumulationAddr.transfer({
            value: 0,
            flag: 128
        });

        emit TrackEvents.TrackComplite(lobby, carAddrToReward);
    }

    function getInfo() external override view returns(
        address _trackRootAddr,
        uint256 _trackId,
        address _formulaAddr,
        address _randomGeneratorAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        uint8[] _regionIndexes,
        uint8[] _regionDifficulties,
        GameLobbyStruct _lobby,
        RegionStruct[] _regions
    ) {
        return(
            trackRootAddr,
            trackId,
            formulaAddr,
            randomGeneratorAddr,
            playerRootAddr,
            parameterRootAddr,
            feeAccumulationAddr,
            regionIndexes,
            regionDifficulties,
            lobby,
            regions
        );
    }

    function destructByRoot(address dst) external override onlyRoot {
        tvm.accept();
        emit TrackEvents.BurnByRoot(msg.sender);
        selfdestruct(dst);
    }

    function withdrawByRoot(uint128 value, address dst) external override onlyRoot {
        tvm.accept();
        dst.transfer({value: value, flag: 0});
    }

    function withdraw(address dst) external onlyRoot {
        tvm.accept();
        selfdestruct(dst);
    }

    modifier onlySelf() {
        require(msg.sender == address(this), TrackErrors.sender_is_not_self);
        _;
    }

    modifier onlyFormula() {
        require(msg.sender == formulaAddr, TrackErrors.sender_is_not_formula);
        _;
    }

    modifier onlyRandomGenerator() {
        require(msg.sender == randomGeneratorAddr, TrackErrors.sender_is_not_random_generator);
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == trackRootAddr, TrackErrors.sender_is_not_track_root);
        _;
    }

}