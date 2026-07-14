git annex fsck --from=web --url='*://web.archive.org*' --incremental-schedule 30d --time-limit 30m --jobs 4

Here is the refined, enterprise-grade `README` for your digital preservation node.

This version integrates **URL-ingestion optimizations** using the verifiable backend, enforces your **strict 3-copy redundancy rule**, and incorporates industry best practices for filename sanitation, automated backup verification, and metadata reliability.

---

# Perma-Asset: Mobile-First Digital Preservation Node

A text-centric, offline-first digital asset pipeline using `git-annex` inside **Termux** on Android. This repository tracks and catalog archives across a personal workstation, Android public storage, Google Drive, and pCloud while strictly preventing duplicate storage overhead.

---

## 1. Storage Topology & Redundancy Policy

To protect data against hardware failures, data rot, or cloud service disruption, this node implements a strict **3-copy redundancy policy**:

* No binary data may be purged (`dropped`) from the local working environment unless git-annex registers that the file exists in at least **3 distinct physical remotes**.
* The system uses the `VURL` (Verifiable URL) backend by default for network downloads, locking down cryptographic file signatures immediately upon ingestion.

```
                      +---------------------------------------+
                      |         CLOUDS (Copies 2 & 3)         |
                      |  [gdrive_export]  &  [pcloud_export]  |
                      +-------------------+-------------------+
                                          ^
                                          | (git annex export)
                                          v
+-----------------------+       +-------------------+       +-----------------------+
| Local PC Workstation  |  <=>  |  Termux Internal  |  ===> | Android Public Storage|
| (Optional Local Sync) |       | (Metadata Engine) |       |  [phone_public]       |
+-----------------------+       +-------------------+       | (Copy 1 on Mobile)    |
                                  [Data Dropped]            +-----------------------+

```

---

## 2. Canonical Directory Tree (`master` branch)

Physical layouts optimize for flat, highly scannable structural paths. This maximizes parsing speed across web UIs and media player databases (VLC, KOReader). Special characters are stripped to ensure cross-platform compatibility.

```
Archive/
├── books/
│   ├── fiction/
│   │   └── Le Guin, Ursula/
│   │       └── The_Dispossessed.epub
│   └── nonfiction/
│       └── science/
│           └── Quantum_Mechanics_Intro.pdf
└── music/
    └── Pink_Floyd/
        └── (1973)_Dark_Side_of_the_Moon/
            ├── 01_-_Speak_to_Me.mp3
            └── 02_-_Breathe.mp3

```

---

## 3. Metadata & Dynamic Views Schema

Instead of nested physical subdirectories, categorical sorting and state flags are decoupled into git-annex's key-value metadata engine.

### Taxonomy Core

| Field | Purpose | Sample Parameters |
| --- | --- | --- |
| `type` | Primary categorization | `books`, `music` |
| `status` | Consumption state | `unread`, `reading`, `completed` |
| `mood` | Contextual soundtracking | `focus`, `workout`, `ambient`, `chill` |
| `priority` | Asset tiering | `high`, `medium`, `low` |

### Setting Tags Natively

```bash
# Tagging a book path
git annex metadata --set type=books --set status=unread "books/fiction/Le_Guin,_Ursula/The_Dispossessed.epub"

# Batch tagging an entire directory
git annex metadata --set type=music --set mood=focus --force "music/Pink_Floyd/(1973)_Dark_Side_of_the_Moon/"

```

### Pivoting to Dynamic Virtual Views

Regenerate your entire folder hierarchy instantly based on tracking flags using the metadata view engine:

```bash
# Virtualize books by their current reading status
git annex view type=books status=*

# Collapse back to physical master layout
git annex vpop

```

---

## 4. Setup & Initialization Inside Termux

Execute this sequence inside Termux to initialize the repository, configure the boundaries, and lock down constraints.

### Step 1: Bootstrap Toolchain

```bash
termux-setup-storage
pkg update && pkg install git git-annex rclone

```

### Step 2: Initialize Repository and Hard Constraints

Initialize the repository within Termux internal space to guarantee absolute compliance with POSIX filesystems.

```bash
mkdir ~/Archive
cd ~/Archive
git init
git annex init "android-termux"

# ENFORCE REDUNDANCY: Require 3 safe copies globally before allowing a local drop
git annex numcopies 3

# Automated metadata generation on ingestion
git config annex.genmetadata true

```

### Step 3: Configure Public Android Directory Link

Creates the target endpoint exposed directly to standard Android user apps.

```bash
git annex initremote phone_public type=directory directory=$HOME/storage/shared/Media encryption=none exporttree=yes

```

### Step 4: Configure Cloud Export Remotes

Connect Google Drive and pCloud destinations using unencrypted export structures for readable cloud interfaces:

```bash
# Google Drive Endpoint
git annex initremote gdrive_export type=external externaltype=rclone target=gdrive_config_name encryption=none exporttree=yes

# pCloud Endpoint via WebDAV
git annex initremote pcloud_export type=webdav url="https://webdav.pcloud.com/Archive" encryption=none exporttree=yes

```

---

## 5. Ingestion & Synchronization Pipelines

### Pipeline A: Ingesting Local Files

Use this cycle when assets are downloaded or placed directly onto the phone storage.

```bash
# 1. Place asset into physical branch tree
mv ~/storage/shared/Download/new_album/ music/Artist/
git annex add music/Artist/new_album/
git commit -m "Ingest local album"

# 2. Tag metadata
git annex metadata --set type=music --set mood=ambient music/Artist/new_album/

# 3. Synchronize file tracking logs
git annex sync

# 4. Push binary content out to all 3 physical target endpoints
git annex export master --to phone_public
git annex export master --to gdrive_export
git annex export master --to pcloud_export

# 5. Flush duplicate local tracking content to free space
# (Safeguarded: Will abort if any of the three exports failed)
git annex drop --from here .

```

### Pipeline B: Direct Network Ingestion (Web Links)

Use this technique to download raw documents directly from the web into the archive structure using verifiable checksum parameters (`VURL`).

```bash
# 1. Download and track direct link using the verified download stream
git annex addurl "https://example.com/files/mechanics.pdf" --file books/nonfiction/science/Quantum_Mechanics.pdf
git commit -m "Ingest science book via addurl"

# 2. Assign catalog tags
git annex metadata --set type=books --set status=unread books/nonfiction/science/Quantum_Mechanics.pdf

# 3. Synchronize metadata logs
git annex sync

# 4. Populate the 3 target nodes
git annex export master --to phone_public
git annex export master --to gdrive_export
git annex export master --to pcloud_export

# 5. Drop cache copy from Termux home directory
git annex drop --from here .

```

---

## 6. Archival Best Practices & Safeguards

* **Export Isolation:** **Never** execute `git annex export` while a virtual metadata view is active (`git annex view`). If run inside a view, git-annex will instantly recreate that temporary tag folder layout directly on your storage remotes, cluttering your target directories. Always ensure your prompt is back on `master` via `git annex vpop`.
* **Filename Sanitization Strategy:** Standardize on replacing spaces with underscores (`_`) and removing strict characters (`:`, `*`, `?`, `"`, `<`, `>`, `|`) when organizing content manually. This ensures that files exported onto shared Android filesystems or WebDAV setups never trigger name conflicts.
* **Trust the Numcopies Failure:** If a `git annex drop` returns an error stating that copies are insufficient, **do not override it**. Run `git annex system` checks to find out which remote failed to sync, or run `git annex list` to verify exactly where your files successfully landed.
* **Data Integrity Auditing:** At least once a season, trigger background checksum verification routines directly against your cloud export spaces from Termux to discover and correct silent data corruption or file drops:
```bash
git annex checkPresent gdrive_export
git annex checkPresent pcloud_export

```
