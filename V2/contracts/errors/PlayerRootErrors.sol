pragma ton-solidity = 0.58.1;

/**
    Reserved codes - 200-299
 */
library PlayerRootErrors {
    uint16 constant contract_has_low_balance = 200;
    uint16 constant sender_is_not_updater = 201;
    uint16 constant low_mint_value = 203;
} 