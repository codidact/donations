# Donations
Small web app to display and adminstrate a list of donors to the Codidact Foundation.

## Installation
Clone the repository. Make sure you have a working Ruby environment.

 * Run `bundle install` to install dependencies
 * Rename `config.sample.yml` to `config.yml` and fill in the values for your setup. You can obtain
   OAuth app keys for the Codidact network at https://meta.codidact.com/oauth/apps.
 * Rename `donations.sample.yml` to `donations.yml`.

That's it!

## Usage
For development, run

```
ruby lib/server.rb
```

For production, add the `APP_ENV` variable:

```
APP_ENV=production ruby lib/server.rb
```

## Contributing
Bug reports and PRs are welcome. Please see the [Codidact Code of Conduct](https://meta.codidact.com/policy/code-of-conduct).

## License
MIT
