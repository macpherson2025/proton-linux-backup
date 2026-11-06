# Proton Linux Backup

An open-source Linux backup utility powered by rclone.

Developed by Meridian Integrations.

## Features

- Supports rclone-compatible storage providers
- Proton Drive support through rclone
- Dry-run mode by default
- Versioned copies of replaced files
- Configurable source and destination
- Backup logging
- Prevention of overlapping backup runs

## Requirements

- Linux
- Bash
- rclone
- flock (util-linux)

## Getting Started

1. Install rclone and configure a storage remote.
2. Clone this repository.
3. Copy `config.example.conf` to `config.conf`.
4. Edit `config.conf` for your environment.
5. Test the backup:

   ./scripts/backup.sh --dry-run

6. Execute the backup:

   ./scripts/backup.sh --run

## Security

Never commit `config.conf`, credentials, encryption keys,
or private rclone configuration files.

For encrypted backups, configure an rclone crypt remote.

## Project Status

Early development. Backup and version-history functionality
have passed initial local testing.

Automated scheduling, retention cleanup, and guided recovery
are planned but not yet implemented.

## License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
