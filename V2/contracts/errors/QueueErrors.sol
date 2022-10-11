pragma ton-solidity = 0.58.1;

/**
    Reserved codes - 600-699
 */
library QueueErrors {
    uint16 constant contract_has_low_balance = 600;
    uint16 constant low_msg_value = 601;
    uint16 constant not_verified_car_msg = 602;
    uint16 constant not_verified_parameter_msg = 603;
}