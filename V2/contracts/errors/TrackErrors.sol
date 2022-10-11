pragma ton-solidity = 0.58.1;

/**
    Reserved codes - 800-899
 */
library TrackErrors {
    uint16 constant sender_is_not_track_root = 800;
    uint16 constant sender_is_not_self = 801;
    uint16 constant sender_is_not_formula = 802;
    uint16 constant sender_is_not_random_generator = 803;
}