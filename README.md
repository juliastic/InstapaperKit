# InstapaperKit

InstapaperKit is a simple Instapaper API wrapper written in Swift.

## Installation

For now, only manual installation is possible.

### Manual Installation

Manually drag the InstapaperKit folder into your project.

## Usage

To log into Instapaper use:
``` swift 
InstapaperAPI.logIn(username, withPassword: password, closure: { (succesful, error) in
    // insert magic here
})
```

If log in was succesful, URLs can be added to the connected account:
``` swift 
InstapaperAPI.add(url, withTitle: title, "", closure: { (succesful, error) in 
    // insert magic here
})
```

## License

InstapaperKit is available under the MIT license. See [LICENSE](https://github.com/juliastic/InstapaperKit/blob/master/LICENSE.md) file for more information.
