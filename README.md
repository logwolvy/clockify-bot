### Clockify Bot
Automates timesheet entry for clockify using project commit history

**NOTE**: This is just a quick solution not comprehensively tested, use with caution

#### USAGE
1. Copy `clockify_bot.rb` file to your project's git repo(local)
2. Fill in `CLOCKIFY_EMAIL`, `CLOCKIFY_PASSWORD`, `PROJECT_NAME` in the copied file
3. Run `ruby clockify_bot.rb from_date to_date`

Example -> `ruby clockify_bot.rb 2020-01-01 2020-01-03`

> COMMAND OPTIONS
- from_date -> mandatory -> format -> YYYY-MM-DD
- to_date -> optional -> format -> YYYY-MM-DD -> defaults to -> system date
