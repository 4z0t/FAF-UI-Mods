# ReUI.Ranges

Modernized and optimized weapon & intel range visualization for **Supreme Commander: Forged Alliance Forever**, built for the **ReUI** framework.

## Features & Improvements over RFA
- **Key-based Ring Container:** Eliminates ring overlap and flickering when units have multiple weapons with the same range or when selected units share identical ranges.
- **Selection Range Filter Mode:** Configure which weapon ranges to display from selection via ReUI Options:
  - `All ranges`: Show all distinct weapon ranges across selected units.
  - `Only min-max`: Show only the minimum engagement range and maximum engagement range across selected units.
  - `Only max`: Show only the maximum weapon engagement range across selected units.
- **Garbage-Free Ring Pooling:** Reuses ring instances instead of churning table allocations on cursor update.
- **ReUI Modern Architecture:** Fully integrated with `ReUI.WorldView` components and `ReUI.Options` reactive menu.
