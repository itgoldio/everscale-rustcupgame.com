pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/IPlayer.sol";
import "../../interfaces/IPlayerRoot.sol";

import "../../access/Ownable.sol";
import "../../access/Manageable.sol";
import "../../access/Mintable.sol";

import "../../errors/PlayerRootErrors.sol";

import "../../abstract/WorkTax.sol";

import "../../resolvers/TrackResolver.sol";
import "../../resolvers/PlayerResolver.sol";

library PlayerRootConstants {
    uint128 constant mint_value = 0.2 ton;
    uint128 constant mint_processing_value = 0.1 ton;
    uint128 constant work_tax_value = 0.05 ton;
}

interface PlayerRootEvents {
    event MintPlayer(
        address playerWalletAddr,
        uint256 totalPoints,
        uint32 totalRaces,
        uint32[] prizePlaces
    );
    event UpdatePlayers(
        uint256 trackId,
        address[] playerAddresses,
        uint256[] totalPoints,
        uint32[] places
    );
}

contract PlayerRoot is
IPlayerRoot,
Ownable,
Mintable,
Manageable,
PlayerResolver,
TrackResolver,
WorkTax,
PlayerRootEvents {
    
    TvmCell playerCode;
    TvmCell trackCode;
    address trackRootAddr;

    constructor(
        uint256 ownerPubkey,
        uint256 minterPubkey,
        uint256 managerPubkey,
        address _trackRootAddr,
        TvmCell _playerCode,
        TvmCell _trackCode
    )
    Ownable(ownerPubkey)
    Mintable(minterPubkey)
    Manageable(managerPubkey)
    WorkTax(PlayerRootConstants.work_tax_value)
    public {
        tvm.accept();
        playerCode = _playerCode;
        trackCode = _trackCode;
        trackRootAddr = _trackRootAddr;
    }

    function mintPlayerByMinter(
        address playerWalletAddr,
        uint256 totalPoints,
        uint32 totalRaces,
        uint32[] prizePlaces
    ) external onlyMinter view returns(address) {
        require(address(this).balance >= PlayerRootConstants.mint_value + PlayerRootConstants.mint_processing_value, PlayerRootErrors.contract_has_low_balance);
        tvm.accept();
        address newStatisticPlayer = new Player {
            code: playerCode,
            value: PlayerRootConstants.mint_value,
            varInit: {
                playerRootAddr: address(this),
                playerWalletAddr: playerWalletAddr
            }
        }(totalPoints, totalRaces, prizePlaces);
        emit PlayerRootEvents.MintPlayer(
            playerWalletAddr,
            totalPoints,
            totalRaces,
            prizePlaces
        );
        return newStatisticPlayer;
    }

    function mintPlayerByWallet() external override view {
        require(msg.value >= PlayerRootConstants.mint_value + PlayerRootConstants.mint_processing_value, PlayerRootErrors.low_mint_value);
        tvm.accept();
        new Player {
            code: playerCode,
            value: PlayerRootConstants.mint_value,
            varInit: {
                playerRootAddr: address(this),
                playerWalletAddr: msg.sender
            }
        }(0, 0, new uint32[](3));
        emit PlayerRootEvents.MintPlayer(
            msg.sender,
            0,
            0,
            new uint32[](3)
        );
    }

    function updatePlayers(uint256 trackId, address[] playerAddresses, uint256[] totalPoints, uint32[] places) external override view {
        require(msg.sender == resolveTrack(trackCode, trackId, trackRootAddr), PlayerRootErrors.sender_is_not_updater);
        tvm.accept();
        for (uint8 i = 0; i < playerAddresses.length; i++) {
            IPlayer(playerAddresses[i]).updateStatisticByPlayerRoot {
                value: _getCalculateTaxValue(1),
                flag: 0
            }(totalPoints[i], places[i]);
        }
        emit PlayerRootEvents.UpdatePlayers(
            trackId,
            playerAddresses,
            totalPoints,
            places
        );
    }

    function changeMinter(uint256 newMinterPubkey) external onlyOwner {
        tvm.accept();
        _changeMinter(newMinterPubkey);
    }

    function changeManager(uint256 newManagerPubkey) external onlyOwner {
        tvm.accept();
        _changeManager(newManagerPubkey);
    }

    function resolvePlayerCodeHash() external view returns(uint256 codeHash) {
        return(tvm.hash(playerCode));
    }

    function setPlayerCode(TvmCell newPlayerCode) external onlyManager {
        tvm.accept();
        playerCode = newPlayerCode;
    }

    function setTrackCode(TvmCell newTrackCode) external onlyManager {
        tvm.accept();
        trackCode = newTrackCode;
    }

    function setTrackRootAddress(address newTrackRootAddr) external onlyManager {
        tvm.accept();
        trackRootAddr = newTrackRootAddr;
    }

    function getInfo() external override view returns(
        TvmCell _playerCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue
    ) {
        return(
            playerCode,
            trackCode,
            trackRootAddr,
            PlayerRootConstants.mint_value,
            PlayerRootConstants.mint_processing_value
        );
    }

    function withdraw(address dest, uint128 value, bool bounce) external pure onlyOwner {
        tvm.accept();
        dest.transfer(value, bounce, 0);
    }

    function destruct(address addr) external onlyOwner {
        tvm.accept();
        selfdestruct(addr);
    }

}