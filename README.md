# slack_cleanser

Auto-leaves slack channels you don't whitelist and auto-leaves direct messages older than 1 day.
Useful for keeping distractions out.

Setup
---
1. Make a `.env` file with a `SLACK_TOKEN=XXX` line. This script uses dotenv to load it.
2. Add `WHITELISTED_CHANNELS=xxx` to `.env` where xxx is a CSV list of channels you allow yourself to stay in
3. Run `bin/slack` (For crontab use `bash -lc "cd path/to/repo/slack && path/to/ruby bin/slack"`)
4. Done!
