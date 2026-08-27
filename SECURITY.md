# Security policy

Do not publish suspected vulnerabilities in a public issue before the affected project has had a reasonable opportunity to respond.

This repository is a temporary mitigation, not an official Basecamp or Omarchy release. Its privileged surface is deliberately limited:

- installed executable paths are root-owned;
- the passwordless command validates exactly one hexadecimal color argument;
- browser policy output has fixed JSON structure and fixed destinations;
- policy directory symlinks are refused;
- existing policy data is backed up before repair.

When reporting a problem, include the hardener version, Omarchy version, audit output, and whether the path was a file, directory, or symlink. Remove personal paths or policy contents that should remain private.
