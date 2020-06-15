# Starling Export

A quick a and simple way to get Starling transactions into QIF and CSV files.


### How to use:

```
ruby starling-export.rb qif --access_token=#{access_token}
ruby starling-export.rb csv --access_token=#{access_token}
```

You may omit the `--access_token=` argument, and use an environmental
variable - `$STARLING_ACCESS_TOKEN` instead.

### access_token

You will need to get a token from [here][token_req], with the
following scopes:

- `account_read`
- `account-identifier:read`
- `balance:read`
- `transaction:read`

[token_req]: https://developer.starlingbank.com/token/list
