# 🏁RustCupGame V2 - Parameter

## About
The `Parameter` smart-contract is a ___SUB-NFT___ (Owned only by developers) for ___NFT___ from the __Rust Cup Game Collection__.

## Resolve `Parameter` address from `ParameterRoot`

1. Open [ton.bytie.moe](https://ton.bytie.moe/executor)
2. Click __Connect wallet__.
3. Load ABI: `ParameterRoot.abi.json`.
4. Paste `ParameterRoot` address & click __Search__.
5. Run local `resolveParameter` function.

|Input|Type|Description|
|-|-|-|
__answerId__|_uint32_|Callback `functionId`, use 0 for run local.|
__parameterCode__|_TvmCell_|`Parameter` code, paste data from file `Parameter.base64`.|
__carNftAddr__|_address_|Address of __Rust Cup Game Collection__ NFT (Car).|
__parameterRootAddr__|_address_|Address of `ParameterRoot` contract.

|Output|Type|Description|
|-|-|-|
__parameterAddr__|_address_|`Parameter` address for this __Rust Cup Game Collection__ NFT (Car).|

## Read `Parameter`

1. Open [ton.bytie.moe](https://ton.bytie.moe/executor)
2. Click __Connect wallet__.
3. Load ABI: `Parameter.abi.json`.
4. Paste `Parameter` address & click __Search__.
5. Run local `getInfo` function.

|Input|Type|Description|
|-|-|-|
__answerId__|_uint32_|Callback `functionId`, use 0 for run local.|

|Output|Type|Description|
|-|-|-|
___parameterRootAddr__|_address_|`ParameterRoot` address.|
___carNftAddr__|_address_|Address of __Rust Cup Game Collection__ NFT (Car).|
___carName__|_string_|Name of __Rust Cup Game Collection__ NFT (Car).|
___carDescription__|_string_|Description of __Rust Cup Game Collection__ NFT (Car).|
___speed__|_uint8_|`Speed` value for __Rust Cup Game Collection__ NFT (Car).|
___acceleration__|_uint8_|`Acceleration` value for __Rust Cup Game Collection__ NFT (Car).|
___braking__|_uint8_|`Braking` value for __Rust Cup Game Collection__ NFT (Car).|
___control__|_uint8_|`Control` value for __Rust Cup Game Collection__ NFT (Car).|
___totalRaces__|_uint32_|All races counter.|
___prizePlaces__|_uint32[]_|__#1__,__#2__ and __#3__ place counter.|

## Events

|Events|Results|Description|
|-|-|-|
__UpdateParameter__|uint32 prizePlace|Prize place from last race.