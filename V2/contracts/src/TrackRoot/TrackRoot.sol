pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/ITrackRoot.sol";
import "../../interfaces/ITrack.sol";

import "../../access/Ownable.sol";
import "../../access/Manageable.sol";

import "../../errors/TrackRootErrors.sol";

import "../../abstract/Regions.sol";
import "../../abstract/WorkTax.sol";

import "../Track/Track.sol";

library TrackRootConstants {
    uint128 constant work_tax_value = 0.15 ton;
}

interface TrackRootEvents {
    event MintTrack(
        address trackAddr,
        GameLobbyStruct lobby
    );
}

contract TrackRoot is ITrackRoot, Ownable, Manageable, Regions, WorkTax, TrackRootEvents {

    address queueAddr;
    address randomGeneratorAddr;
    address formulaAddr;
    address playerRootAddr;
    address parameterRootAddr;
    address feeAccumulationAddr;
    TvmCell trackCode;
    uint256 trackSupply;

    constructor(
        uint256 ownerPubkey,
        uint256 managerPubkey,
        address _queueAddr,
        address _randomGeneratorAddr,
        address _formulaAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        TvmCell _trackCode
    )
    Ownable(ownerPubkey)
    Manageable(managerPubkey)
    WorkTax(TrackRootConstants.work_tax_value)
    public {
        tvm.accept();
        queueAddr = _queueAddr;
        randomGeneratorAddr = _randomGeneratorAddr;
        formulaAddr = _formulaAddr;
        playerRootAddr = _playerRootAddr;
        parameterRootAddr = _parameterRootAddr;
        feeAccumulationAddr = _feeAccumulationAddr;
        trackCode = _trackCode;
    }

    function mintTrack(GameLobbyStruct lobby) external override onlyQueue {
        tvm.accept();
        address newTrack = new Track {
            code: trackCode,
            value: msg.value - _getCalculateTaxValue(lobby.maxPlayers),
            varInit: {
                trackRootAddr: address(this),
                trackId: trackSupply
            }
        }(
            formulaAddr,
            randomGeneratorAddr,
            playerRootAddr,
            parameterRootAddr,
            feeAccumulationAddr,
            _regionsToArray(),
            lobby
        );

        emit TrackRootEvents.MintTrack(
            newTrack,
            lobby
        );

        trackSupply++;
    }

    function _regionsToArray() internal view returns(RegionStruct[] regionsArray) {
        for ((, RegionStruct region): m_regions) {
            regionsArray.push(region);
        }
    }

    function changeManager(uint256 newManagerPubkey) external onlyOwner {
        tvm.accept();
        _changeManager(newManagerPubkey);
    }

    function addRegion(
        uint8 id,
        string regionName,
        uint8 vel
    ) external onlyManager {
        tvm.accept();
        _addRegion(
            id,
            regionName,
            vel
        );
    }

    function removeRegion(uint8 id) external onlyManager {
        tvm.accept();
        _removeRegion(id);
    }

    function resolveTrackCodeHash() external view returns(uint256 codeHash) {
        return(tvm.hash(trackCode));
    }

    function setQueueAddress(address newQueueAddress) external onlyManager {
        tvm.accept();
        queueAddr = newQueueAddress;
    }

    function setRandomGeneratorAddress(address newRandomGeneratorAddr) external onlyManager {
        tvm.accept();
        randomGeneratorAddr = newRandomGeneratorAddr;
    }

    function setFormulaAddress(address newFormulaAddress) external onlyManager {
        tvm.accept();
        formulaAddr = newFormulaAddress;
    }

    function setPlayerRootAddress(address newPlayerRootAddress) external onlyManager {
        tvm.accept();
        playerRootAddr = newPlayerRootAddress;
    }

    function setParameterRootAddr(address newParameterRootAddr) external onlyManager {
        tvm.accept();
        parameterRootAddr = newParameterRootAddr;
    }

    function setFeeAccumulationAddr(address newFeeAccumulationAddr) external onlyManager {
        tvm.accept();
        feeAccumulationAddr = newFeeAccumulationAddr;
    }

    function setTrackCode(TvmCell newTrackCode) external onlyManager {
        tvm.accept();
        trackCode = newTrackCode;
    }

    function getInfo() external override view returns(
        address _queueAddr,
        address _randomGeneratorAddr,
        address _formulaAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        TvmCell _trackCode,
        uint256 _trackSupply
    ) {
        return(
            queueAddr,
            randomGeneratorAddr,
            formulaAddr,
            playerRootAddr,
            parameterRootAddr,
            feeAccumulationAddr,
            trackCode,
            trackSupply
        );
    }

    function withdraw(address dest, uint128 value, bool bounce) external pure onlyOwner {
        tvm.accept();
        dest.transfer(value, bounce, 0);
    }

    function trackDestruct(address trackAddr, address dst) external pure onlyOwner {
        tvm.accept();
        ITrack(trackAddr).destructByRoot{value: 0.05 ton, flag: 1}(dst);
    }

    function trackWithdraw(uint128 value, address trackAddr, address dst) external pure onlyOwner {
        tvm.accept();
        ITrack(trackAddr).withdrawByRoot{value: 0.05 ton, flag: 1}(value, dst);
    }

    function destruct(address addr) external onlyOwner {
        tvm.accept();
        selfdestruct(addr);
    }

    modifier onlyQueue() {
        require(msg.sender == queueAddr, TrackRootErrors.sender_is_not_queue);
        _;
    }

}