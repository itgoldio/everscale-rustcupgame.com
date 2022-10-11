pragma ton-solidity = 0.58.1;

/**
    Reserved codes - 100-199
 */
library AccessErrors {
    uint16 constant pubkey_is_zero = 101;
    uint16 constant sender_is_not_owner = 102;
    uint16 constant sender_is_not_minter = 103;
    uint16 constant sender_is_not_manager = 104;
    uint16 constant paused = 105;
    uint16 constant unpaused = 106;
}