## ⛽GasTank

#### GasTank is a secure on-chain ETH vault that allows users to deposit and manage balances individually.
#### The contract owner can authorize trusted pipes to interact with the system. Pipes and the owner can burn (deduct) ETH from user balances when a service has been completed, collecting the cost into the owner's wallet.
#### This setup allows users to prepay for services, while giving the owner (or trusted executors) the ability to charge users efficiently and safely.


## Usage

```solidity
import {GasTank} from "./GasTank.sol";

contract MyFactory {
    
    GastTank private immutable gasTank;

    constructor() {
        
        address owner = msg.sender;
        address facility = address(this);
        
        //Initialize GasTank
        gasTank = new GasTank(owner, facility);
        
        // Allow the factory to transfer ETH from the tank
        gasTank.setPipe(facility, true);
    }

    function doSomething() public {
        uint256 startGas = gasLeft();

        // do something

        uint256 cost = ( startGas - gasLeft() ) * tx.gasprice;
        
        // Burn the cost for the service
        gasTank.burn(msg.sender, cost);
        
    }
}
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
