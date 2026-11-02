# Omarchy public status

Status date: 2026-11-02

This is a sanitized operational status intended for publication. It contains no
passwords, private keys, certificates, recovery material, personal paths, device
identifiers, or other host-specific secrets.

## Update

- Omarchy version: `4.0.6-1`
- Full system update completed successfully.
- Arch package databases are synchronized and system packages are current.
- A boot-selectable system snapshot was created during the update.
- Package-cache pruning removed 9 cached packages (about 636 MiB).
- Orphan packages were reviewed and intentionally retained:
  `gst-plugin-gtk`, `hyprwayland-scanner`, `vulkan-headers`.
- The configured Node.js version remains `26.7.0`; no mise range change was
  applied.

## Boot security

- UEFI Secure Boot is enabled.
- The system retains the platform/vendor and Microsoft trust material required
  for the supported dual-boot setup.
- No Secure Boot keys, certificates, recovery keys, or firmware details are
  recorded in this public note.

## Agent and browser safeguards

- The AI-agent kill switch is installed and currently enabled.
- The AI-agent hardener remains installed.
- The browser-policy hardening hook remains installed.
- The browser-policy hardener was originally verified against an older Omarchy
  release; after the upgrade it must be treated as requiring a fresh audit
  before any write/repair operation. No repair operation is recorded here.

## Publication boundary

Do not publish alongside this note:

- Secure Boot keys, certificates, signatures, hashes tied to private artifacts,
  recovery codes, passwords, tokens, or SSH material;
- full home-directory paths, usernames, machine serials, UUIDs, MAC addresses,
  disk layouts that identify the host, or firmware screenshots;
- raw command output that may expose the above information.

The detailed Secure Boot handoff remains private operational documentation and
is not part of the public status record.
