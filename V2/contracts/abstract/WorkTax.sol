pragma ton - solidity = 0.58 .1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

contract WorkTax {

    uint128 contractTaxValuePerUnit;

    constructor(uint128 _contractTaxValuePerUnit) public {
        tvm.accept();
        contractTaxValuePerUnit = _contractTaxValuePerUnit;
    }

    function _getCalculateTaxValue(uint32 multiplier) internal view returns(uint128) {
        return(contractTaxValuePerUnit * multiplier);
    }
    
    function getContractTaxValuePerUnit() external view returns(uint128) {
        return(contractTaxValuePerUnit);
    }

}