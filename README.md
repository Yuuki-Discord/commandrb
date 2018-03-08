

# [Discontinued] Commandrb
Commandrb has been adandoned in favour of making Yuuki-Bot's command system from scratch and specifically designed and integrated with the rest of the Yuuki-Bot codebase. This change was made to allow easy customisation of Yuuki's commands without the need to support a whole seperate Ruby gem and all its many use-cases.

OLD README:

<hr>
A customisable and (probably) easy to use commands system for discordrb
It's probably not recommended to use this in it's early stages (< 1.0) because it will be riddled with bugs and features that don't work as intended.
However, feel free to use it if you want, just don't be surprised when it doesn't work exactly the way you want it to. (If you find an issue feel free to report it, just don't act all entitled, you were warned.)

# Creating a bot with Commandrb

## Requirements
- Ruby 2.1+ (2.3.1+ is recommended)
- [discordrb](https://github.com/meew0/discordrb) 3.0+

## Install
You can do this by one of two ways:
The most simple is to just install the gem and then get developing:
```sh 
gem install commandrb
```

However, espcially in a large project, it is recommended to use bundler (`gem install bundler`) and add this to your `Gemfile`:
```sh 
gem 'commandrb'
```
You can then install commandrb for your project with `bundle install` and manage other dependancies alongside it in your gemfile.

## Usage
A simple bot can be made like so:
```ruby
require 'discordrb'
require 'commandrb'

cbot = CommandrbBot.new(
    {
      token: '<insert token here>',
      client_id: 168123456789123456,
      prefixes: ['!']
    }
)

cbot.add_command(:ping, 
  code: proc { |event,args|
    event.respond('Pong!')
  }
)

cbot.bot.run
```
The above example can be used as a means of testing if commandrb is installed properly. Replace the token and client ID in the example with your own and run it. The bot should respond to every `!ping` with `Pong!`

If this example works then congratulations, you have successfully installed commandrb! You can now check out the docs for more information, or check the `examples` folder on GitHub to see a couple more complex examples of bots.

For example of a large bot using this system, you can view my own bot, [Yuuki-Bot](https://github.com/Seriell/Yuuki-Bot) and learn from the examples inside it.

## Updating
It is best to update commandrb alongside all your other gems.

If you installed as an ordinary gem:
```sh 
gem update
```

If you are using bundler:
```sh 
bundle update
```

That should update commandrb and all your other gems to the latest versions.

If you instead for some reason need to update just commandrb as an ordinary gem, it would be `gem update commandrb`

## Versioning
While the bot is still in the testing phase (Before 1.0.0), I reserve the right to make any breaking changes at any time without warning. Please check the commit history to view the changes until I start creating a changelog.

After 1.0.0 has been released, all breaking changes (Which require editing your bot) will only be on full realeases (For example 1.0.0 -> 2.0.0). These releases may contain breaking changes which require you to edit your bot. Such releases will also contain full changelogs detailing what is required for you to convert your bot to a different commandrb version. Every attempt will be made to make the changes you'll need make as minimal as possible. 

For minor releases (For example 1.0.0 -> 1.1.0) there will be no breaking changes, but changelogs will be given.

Changelogs may not be given for all bugfix versions (For example 1.0.0 -> 1.0.1) however such changes will be detailed in the next minor release changelogs. As the name suggests, bugfix changes will be reserved for bug fixes and patches only, and will not contain any new features. These releases will not break any bots, and should be installed as soon as possible to maintain the stability and security of your bot.

Changes will be pushed to the master branch at GitHub before release, this means that the GitHub version may contain new features and fixes compared to the release versions.<br />
To use the git version in your project, add the following to your Gemfile: (If you're not using bundler, now is a good time to start)
```ruby
gem 'commandrb', git: 'https://github.com/Seriell/commandrb.git'
```
Please note that the git version does not include official changelogs outside of the commit history. In addition, changes to the git version may not be fully tested in all cases, so take care when using it for an important project.

## Bot Examples
The following is a list of sponsered projects that are using commandrb, and can be used as examples for commandrb usage:

- [Yuuki-Bot](https://github.com/Seriell/Yuuki-Bot),  by Seriel

To add to this list, either add the project to the above list in the same format via a Pull Request, or email me at `seriel@fl0.co`

## Support 
Please report any issues to `@Seriel#3760` | `<@228574821590499329>` on Discord, or open an Issue on Github! <br />
You can also join our server for support! https://discord.gg/43SaDy6 <br />

## Credits
Kudos to the following users for helping me ([Seriel](https://github.com/Seriell)) out:

- [meew0](https://github.com/meew0/) for [discordrb](https://github.com/meew0/discordrb)
- [Spotlight](https://github.com/spotlightishere) for ideas, help and general support.
