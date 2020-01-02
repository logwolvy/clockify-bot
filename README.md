## Clockify Bot
Automates timesheet entry for clockify using project commit history

**NOTE**: This is just a quick solution not comprehensively tested, use with caution

#### Setup
- `cp config.yml.example config.yml` and fill your details in `config.yml`

#### Usage
- Run `ruby clockify_bot.rb from_date to_date`

> Arguments
- from_date -> mandatory -> format -> YYYY-MM-DD
- to_date -> optional -> format -> YYYY-MM-DD -> defaults to -> system date

#### Example
- `ruby clockify_bot.rb 2020-01-01 2020-01-03`
