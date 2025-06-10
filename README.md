## ⛽GasTank

A simple smart contract for managing user-funded gas balances.

## Features

- Users can deposit and withdraw native tokens (e.g. ETH)
- Authorized addresses (“facilities” and “pipes”) can transfer or burn user balances
- Owner-controlled access and pausable
- EOAs only — contracts cannot deposit/withdraw

## Use Case

Useful for bots or services that execute transactions on behalf of users using pre-funded gas.

## Tech

- Solidity `^0.8.0`
- OpenZeppelin (Ownable, Pausable, ReentrancyGuard)

## License

MIT



## Usage

```solidity
import {GasTank} from "./GasTank.sol";

contract MyFactory {
    
    GastTank private immutable gasTank;

    constructor() {
        
        address owner = msg.sender;
        address factory = address(this);
        
        // Initialize GasTank
        gasTank = new GasTank(owner);
        
        // Allow the factory to set pipes
        gasTank.addFacility(factory);
        
        // Allow the factory to transfer ETH from the tank
        gasTank.addPipe(factory);
        
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
