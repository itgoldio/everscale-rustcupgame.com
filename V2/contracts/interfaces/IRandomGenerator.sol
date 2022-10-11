pragma ton-solidity = 0.58.1;

interface IRandomGenerator {
    function getRandomArray(uint8 size, uint8 limit, uint8 offset) external responsible view returns(uint8[] randomArray);
}