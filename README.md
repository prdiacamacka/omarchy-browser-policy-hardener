# Omarchy Browser Policy Hardener

Temporary mitigation for [basecamp/omarchy issue #5547](https://github.com/basecamp/omarchy/issues/5547): older Omarchy installations create managed browser-policy directories with mode `0777`. A local process can then plant mandatory policies such as forced extensions, proxies, or disabled security controls.

> [!IMPORTANT]
> This is an independent, unofficial community project. It is not affiliated
> with, maintained by, sponsored by, or endorsed by the Omarchy project,
> Basecamp, 37signals, or Omacom. Omarchy is named only to identify the affected
> system and compatibility. For official Omarchy information, use
> [omarchy.org](https://omarchy.org/) and
> [basecamp/omarchy](https://github.com/basecamp/omarchy).

This project packages the constrained writer proposed in [PR #8276](https://github.com/basecamp/omarchy/pull/8276) and adds:

- read-only audit mode;
- backups before every repair;
- Chromium, Google Chrome, Microsoft Edge, Brave and Brave Origin repair;
- Firefox and Zen Browser distribution-policy repair;
- refusal of symlinked or non-directory policy paths;
- preservation of safe root-owned administrator policies;
- a pacman hook that rechecks permissions after relevant upgrades;
- uninstall support.

## Supported version

The write patch is intentionally limited to **Omarchy 4.0.1-1**, the version against which it was verified. Audit mode works on other versions. The update hook will still secure existing policy directories after a version change, but it will not overwrite scripts from an unknown Omarchy version.

Once Omarchy ships an official fix for #5547, prefer the official update and uninstall this temporary mitigation.

## Quick start

Clone the repository and audit first:

```bash
git clone <repository-url>
cd omarchy-browser-policy-hardener
./omarchy-browser-policy-hardener --audit
```

Install only after reviewing the audit and source:

```bash
sudo ./omarchy-browser-policy-hardener --install
```

Verify:

```bash
./omarchy-browser-policy-hardener --audit
```

A secure Chromium-family result is:

```text
drwxr-xr-x 755 root:root .../policies/managed
-rw-r--r-- 644 root:root .../policies/managed/color.json
```

## Commands

```text
--audit      Inspect without changing anything. Exits nonzero if unsafe.
--install    Back up, install the mitigation, repair paths, and add hook.
--repair     Reapply checks and repairs; also used by the pacman hook.
--uninstall  Restore original Omarchy scripts and remove tooling/hook.
--version    Print the hardener version.
```

## What installation changes

The installer:

1. Saves browser policy directories under `/var/lib/omarchy-browser-policy-hardener/backups/`.
2. Saves the original Omarchy scripts once under `/var/lib/omarchy-browser-policy-hardener/originals/`.
3. Installs the constrained policy writer and patched Omarchy 4.0.1 browser scripts.
4. Adds `/etc/sudoers.d/omarchy-theme-browser-policy`, allowing only the root-owned writer without a password. The writer accepts exactly one `#RRGGBB` value and writes fixed JSON.
5. Secures existing browser policies.
6. Adds `/etc/pacman.d/hooks/95-omarchy-browser-policy-hardener.hook`.

The hardener does not create policy directories for browsers that are not installed.

## Repair behavior

For Chromium-family policy directories it:

- requires a real directory, never a symlink;
- sets `root:root 0755`;
- preserves regular root-owned policy files that are not group/world writable;
- replaces `color.json` atomically as `root:root 0644`;
- removes other unsafe entries after backing them up.

For Firefox and Zen distribution directories it:

- requires a real directory;
- sets `root:root 0755`;
- preserves safe root-owned files/directories;
- removes unsafe entries after backup;
- restores Omarchy's packaged `policies.json` only from a trusted root-owned source.

## Uninstall

```bash
sudo /usr/local/libexec/omarchy-browser-policy-hardener --uninstall
```

Uninstall restores the scripts saved during first installation and removes the helper, sudoers rule, files, and pacman hook. It intentionally leaves browser policy directories hardened. Backups remain in `/var/lib/omarchy-browser-policy-hardener/`.

## Security notes

- Read the script before running it as root.
- Do not pipe an unverified network download directly to `sudo bash`.
- A warning about a symlinked policy directory requires manual administrator review; the hardener will not follow or replace it.
- The threat requires local code execution. This is not, by itself, a remote unauthenticated compromise.

## Attribution

The constrained writer and patched Omarchy browser scripts are based on Basecamp Omarchy PR #8276, commit `a1d35e73c01ee7fb27df6f9b52616d04f511ec81`, under Omarchy's MIT license.

The upstream copyright and license notice retained for those derived portions
is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Potential vulnerabilities in Omarchy itself should be reported privately using
[Omarchy's security process](https://omarchy.org/security/), not published here
before the upstream team has had an opportunity to investigate and fix them.

## License

MIT. See [LICENSE](LICENSE).
