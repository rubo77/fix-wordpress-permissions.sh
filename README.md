# fix-wordpress-permissions.sh

A script to configure WordPress file permissions based on recommendations from https://wordpress.org/support/article/hardening-wordpress/#file-permissions

Compatible with WordPress 6.8.2 and includes enhanced security options.

## usage:

    ./fix-wordpress-permissions.sh [-y] [-s] [wordpress root directory] [wordpress owner] [wordpress group] [webserver group]
    -y, --yes     dont ask for confirmation
    -s, --secure  use enhanced security permissions (770/660 instead of 775/664)
                  prevents other users from accessing WordPress files

## Permission Modes:

### Standard Mode (default)
- Directories: 755 (owner: rwx, group: rx, others: rx)
- Files: 644 (owner: rw, group: r, others: r)
- wp-content directories: 775 (owner: rwx, group: rwx, others: rx)
- wp-content files: 664 (owner: rw, group: rw, others: r)
- wp-config.php: 660 (owner: rw, group: rw, others: none)

### Enhanced Security Mode (-s flag)
- Directories: 750 (owner: rwx, group: rx, others: none)
- Files: 640 (owner: rw, group: r, others: none)
- wp-content directories: 770 (owner: rwx, group: rwx, others: none)
- wp-content files: 660 (owner: rw, group: rw, others: none)
- wp-config.php: 660 (owner: rw, group: rw, others: none)

The enhanced security mode prevents other users on the server from accessing WordPress files, providing better security in shared hosting environments.
