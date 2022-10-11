pragma ton-solidity = 0.58.1;

import "../src/Track/Track.sol";

contract TrackResolver {

    function resolveTrack(TvmCell trackCode, uint256 trackId, address trackRootAddr) public responsible pure returns(address trackAddr) {
        return {
            value: 0,
            flag: 64
        }(address(tvm.hash(_buildTrackState(trackCode, trackId, trackRootAddr))));
    }

    function _buildTrackState(TvmCell trackCode, uint256 trackId, address trackRootAddr) internal pure returns(TvmCell) {
        return tvm.buildStateInit({
            contr: Track,
            varInit: {
                trackRootAddr: trackRootAddr,
                trackId: trackId
            },
            code: trackCode
        });
    }

}