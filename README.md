# slack_cleanser

Auto-leaves slack channels you don't whitelist and auto-leaves direct messages older than 1 day.
Useful for keeping distractions out.

Setup
---
1. Make a `.env` file with a `SLACK_TOKEN=XXX` line. This script uses dotenv to load it.
2. Customize your `lib/config/permitted_channels` file
3. Run `bin/slack` (For crontab use `bash -lc "cd path/to/repo/slack && path/to/ruby bin/slack"`)
4. Done!
