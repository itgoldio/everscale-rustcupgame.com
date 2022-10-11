pragma ton-solidity = 0.58.1;

interface ICarNftData {
    function getInfo() external view responsible returns(
        uint256 id, 
        address owner, 
        address manager, 
        address collection
    );
}